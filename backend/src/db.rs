use super::data::{Message, OutMessage, Thread};
use super::schema::{messages, threads};
use chrono::{NaiveDateTime, Utc};

use diesel::sql_query;
use diesel::sql_types::{Integer, Text, Timestamp};
use diesel::RunQueryDsl;
use rocket_contrib::databases::diesel;

#[database("db")]
pub struct Db(diesel::PgConnection);

#[derive(QueryableByName)]
struct Id {
    #[sql_type = "Integer"]
    id: i32,
}

#[derive(QueryableByName)]
#[table_name = "messages"]
struct DbMessage {
    no: i32,
    name: Option<String>,
    trip: Option<String>,
    text: String,
}

#[derive(QueryableByName)]
#[table_name = "threads"]
struct DbThread {
    id: i32,
    last_reply_no: i32,
    bump: NaiveDateTime,
}

// TODO: wrap into transactions

impl Db {
    pub fn new_thread(&self, msg: Message) {
        let now = Utc::now().naive_utc();

        let thread_id = sql_query(r"
            INSERT INTO threads(last_reply_no, bump)
            VALUES (0, $1)
            RETURNING id
        ")
        .bind::<Timestamp, _>(now)
        .get_result::<Id>(&self.0)
        .unwrap()
        .id;

        sql_query(r"
            INSERT INTO messages
            ( thread_id, no, sender, text, ts )
            VALUES (
                $1, 0, 'sender', $2, $3
            )
        ")
        .bind::<Integer, _>(thread_id)
        .bind::<Text, _>(msg.text)
        .bind::<Timestamp, _>(now)
        .execute(&self.0)
        .unwrap();
    }

    pub fn get_threads_before(&self, ts: u32, limit: u32) -> Vec<Thread> {
        let threads = sql_query(r"
            SELECT id, last_reply_no, bump
              FROM threads
             WHERE bump > $1
             ORDER BY (bump, id) ASC
             LIMIT $2
        ")
        .bind::<Timestamp, _>(NaiveDateTime::from_timestamp(ts as i64, 0))
        .bind::<Integer, _>(limit as i32)
        .load::<DbThread>(&self.0)
        .unwrap();

        threads
            .iter()
            .map(|thread| Thread {
                id: thread.id as u32,
                op: self.get_op(thread.id),
                last: Vec::new(),
            })
            .collect()
    }

    fn get_op(&self, thread_id: i32) -> OutMessage {
        let op = sql_query(r"
            SELECT *
              FROM messages
             WHERE thread_id = $1
               AND no = 0
        ")
        .bind::<Integer, _>(thread_id)
        .get_result::<DbMessage>(&self.0)
        .unwrap();

        OutMessage {
            no: op.no as u32,
            name: op.name.unwrap_or("Anonymous".to_string()),
            trip: op.trip.unwrap_or("".to_string()),
            text: op.text,
        }
    }
}