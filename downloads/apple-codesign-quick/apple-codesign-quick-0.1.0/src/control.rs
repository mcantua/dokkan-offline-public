use crate::error::{CodeSignError, Result};

pub type StopPredicate<'a> = dyn Fn() -> bool + Send + Sync + 'a;

pub(crate) fn check_stop(should_stop: &StopPredicate<'_>) -> Result<()> {
    if should_stop() { Err(CodeSignError::Cancelled) } else { Ok(()) }
}
