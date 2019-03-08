use super::data::{NewMessage, NewThread};
use super::limits::LIMITS;

pub fn validate_thread(mut thr: NewThread) -> Result<NewThread, (&'static str, &'static str)> {
    thr.msg = validate_message(thr.msg)?;
    thr.subject = trim(thr.subject);
    if let Some(subject) = thr.subject.clone() {
        if subject.len() > LIMITS.msg_subject_len {
            return Err((
                "Subject is too long.",
                "message.subject_long",
            ))
        }
    }
    Ok(thr)
}

pub fn validate_message(mut msg: NewMessage) -> Result<NewMessage, (&'static str, &'static str)> {
    msg.text = msg.text.trim().to_owned();
    msg.name = trim(msg.name);
    msg.secret = trim(msg.secret);
    msg.password = trim(msg.password);
    if msg.text.len() == 0 {
        return Err(("Text should not be empty.", "message.text_empty"));
    }
    if msg.text.len() > LIMITS.msg_text_len {
        return Err((
            "Text should be no more than 4096 characters long.",
            "message.text_long",
        ));
    }
    if let Some(name) = msg.name.clone() {
        if name.len() > LIMITS.msg_name_len {
            return Err((
                "Name should be no more than 32 characters long.",
                "message.name_long",
            ));
        }
    }
    Ok(msg)
}

fn trim(a: Option<String>) -> Option<String> {
    a.map(|s| s.trim().to_owned()).filter(|s| !s.is_empty())
}
