use dathos_engine::{EngineModule, GameState};
use rodio::source::{SineWave, Source};
use rodio::{default_output_device, output_devices, play_raw, Device, DeviceTrait};
use rutie::{AnyObject, Class, Integer, Module, NilClass, Object, Symbol};
use std::time::Duration;

wrappable_struct!(ToneInner, ToneWrapper, TONE_WRAPPER);

#[derive(Clone, Copy, Debug)]
enum Note {
    C,
    CsDf,
    D,
    DsEf,
    E,
    F,
    FsGf,
    G,
    GsAf,
    A,
    AsBf,
    B,
}

module!(Tone);

pub struct ToneInner {
    pending: Vec<ToneSound>,
}

pub struct ToneModule {
    device: Device,
}

#[derive(Debug)]
struct ToneSound {
    note: Note,
    octave: usize,
}

#[rustfmt::skip]
methods!(
    Tone,
    _itself,

    fn play_tone(note: Symbol, octave: Integer) -> NilClass {
        _itself
            .instance_variable_get("@inner")
            .get_data_mut(&*TONE_WRAPPER)
            .pending.push(ToneSound {
                note: From::from(note.unwrap().to_string()),
                octave: octave.map(|o| o.to_u64() as usize).unwrap_or(4),
            });
        NilClass::new()
    }
);

impl From<String> for Note {
    fn from(s: String) -> Self {
        match s.as_ref() {
            "c" => Note::C,
            "c_sharp" | "d_flat" => Note::CsDf,
            "d" => Note::D,
            "d_sharp" | "e_flat" => Note::DsEf,
            "e" => Note::E,
            "f" => Note::F,
            "f_sharp" | "g_flat" => Note::FsGf,
            "g" => Note::G,
            "g_sharp" | "a_flat" => Note::GsAf,
            "a" => Note::A,
            "a_sharp" | "b_flat" => Note::AsBf,
            "b" => Note::B,
            _ => Note::A,
        }
    }
}

impl Into<f32> for Note {
    fn into(self) -> f32 {
        match self {
            Note::C => 261.63,
            Note::CsDf => 277.18,
            Note::D => 293.66,
            Note::DsEf => 311.13,
            Note::E => 329.63,
            Note::F => 349.23,
            Note::FsGf => 369.99,
            Note::G => 399.0,
            Note::GsAf => 415.3,
            Note::A => 440.0,
            Note::AsBf => 466.16,
            Note::B => 493.88,
        }
    }
}

impl ToneInner {
    fn new() -> Self {
        ToneInner {
            pending: Vec::new(),
        }
    }
}

impl ToneModule {
    pub fn build() -> Self {
        let device = output_devices()
            .unwrap()
            .find(|d| d.name().unwrap() == "ZoomAudioDevice")
            .unwrap_or_else(|| default_output_device().unwrap());
        println!("Using device: {:?}", device.name());
        ToneModule { device }
    }
}

impl<G> EngineModule<G> for ToneModule
where
    G: GameState,
{
    fn init(&mut self, _: &mut G) {
        let mut module = Module::new("Tone");

        let inner: AnyObject =
            Class::from_existing("Object").wrap_data(ToneInner::new(), &*TONE_WRAPPER);
        module.instance_variable_set("@inner", inner);

        module.def_self("play!", play_tone);
    }

    fn post_update(&mut self, _: &mut G) {
        Module::from_existing("Tone")
            .instance_variable_get("@inner")
            .get_data_mut(&*TONE_WRAPPER)
            .pending
            .drain(..)
            .for_each(|ts| {
                let mut frequency = Into::<f32>::into(ts.note);
                frequency *= 2.0f32.powi(ts.octave as i32 - 4);
                play_raw(
                    &self.device,
                    SineWave::new(frequency.round() as u32)
                        .take_duration(Duration::from_millis(500)),
                );
            });
    }
}
