#![feature(associated_type_defaults)]
#![feature(box_patterns)]
#![feature(box_syntax)]
#![feature(clamp)]
#![feature(const_fn)]
#![feature(div_duration)]
#![feature(drain_filter)]
#![feature(fn_traits)]
#![feature(trait_alias)]
#![feature(try_blocks)]
#![feature(unboxed_closures)]

#[macro_use]
extern crate lazy_static;
#[macro_use]
extern crate rutie;

use crate::modules::{SlackModule, ToneModule};
use dathos_engine::{Engine, EngineError, EngineModule, GameState, WindowOptions};
use std::path::PathBuf;

mod modules;

fn main() {
    let result = Engine::build(
        PathBuf::from("./scripts/main.rb"),
        WindowOptions {
            width: 640,
            height: 360,
            title: "Community Orchestra Game".to_string(),
        },
    )
    .with_module(SlackModule::build())
    .with_module(ToneModule::build())
    .run();

    if let Err(e) = result {
        println!("Error: {:?}", e);
    }
}
