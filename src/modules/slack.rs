use dathos_engine::{EngineModule, GameState};
use rutie::{AnyObject, Array, Class, Hash, Module, Object, RString, Symbol};
use slack::api::groups::HistoryRequest;
use slack::api::Message;
use std::sync::mpsc::{channel, Receiver};
use std::time::Duration;

wrappable_struct!(SlackInner, SlackWrapper, SLACK_WRAPPER);

module!(Slack);

#[derive(Debug)]
struct SlackMessage {
    user: String,
    text: String,
}

pub struct SlackInner {
    messages: Vec<SlackMessage>,
}

pub struct SlackModule {
    messages: Receiver<SlackMessage>,
}

#[rustfmt::skip]
methods!(
    Slack,
    _itself,

    fn slack_drain_inputs() -> Array {
        let mut inner = _itself.instance_variable_get("@inner");
        let inner_wrapped = inner.get_data_mut(&*SLACK_WRAPPER);
        let mut messages = Array::new();
        inner_wrapped.messages.drain(..).map(|message| {
            let mut hash = Hash::new();
            hash.store(Symbol::new("user"), RString::new_utf8(&message.user));
            hash.store(Symbol::new("text"), RString::new_utf8(&message.text));
            hash
        }).for_each(|message| {
            messages.push(message);
        });
        messages
    }
);

impl SlackModule {
    pub fn build() -> Self {
        let (sender, receiver) = channel();
        std::thread::spawn(move || {
            let client = slack::api::default_client().unwrap();
            let token = std::env::var("SLACK_API_TOKEN").unwrap();
            let group_id = std::env::var("SLACK_GROUP_ID").unwrap();
            let mut oldest_timestamp: Option<String> = None;
            loop {
                let history = slack::api::groups::history(
                    &client,
                    &token,
                    &HistoryRequest {
                        channel: &group_id,
                        oldest: oldest_timestamp.as_deref(),
                        inclusive: Some(false),
                        ..Default::default()
                    },
                );
                let has_more = if let Ok(history) = history {
                    if let Some(messages) = history.messages {
                        if messages.len() == 0 {
                            continue;
                        }

                        oldest_timestamp = messages
                            .iter()
                            .filter_map(|message| match message {
                                Message::Standard(message) => message.ts.clone(),
                                _ => None,
                            })
                            .next();

                        messages
                            .iter()
                            .filter_map(|message| match message {
                                Message::Standard(message) => {
                                    try {
                                        SlackMessage {
                                            user: message.user.clone()?,
                                            text: message.text.clone()?,
                                        }
                                    }
                                }
                                _ => None,
                            })
                            .for_each(|message| {
                                let _ = sender.send(message);
                            });
                    }

                    history.has_more.unwrap_or(false)
                } else {
                    false
                };

                if !has_more {
                    std::thread::sleep(Duration::from_secs(1));
                }
            }
        });

        SlackModule { messages: receiver }
    }
}

impl<G> EngineModule<G> for SlackModule
where
    G: GameState,
{
    fn init(&mut self, _: &mut G) {
        let mut module = Module::new("Slack");

        let inner: AnyObject = Class::from_existing("Object").wrap_data(
            SlackInner {
                messages: Vec::new(),
            },
            &*SLACK_WRAPPER,
        );
        module.instance_variable_set("@inner", inner);

        module.def_self("drain_input!", slack_drain_inputs);
    }

    fn pre_update(&mut self, _: &mut G) {
        while let Ok(message) = self.messages.try_recv() {
            let mut inner = Module::from_existing("Slack").instance_variable_get("@inner");
            let inner_wrapped = inner.get_data_mut(&*SLACK_WRAPPER);
            inner_wrapped.messages.push(message);
        }
    }
}
