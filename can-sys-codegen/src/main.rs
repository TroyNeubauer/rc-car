use dbc_codegen::{Config, FeatureConfig, codegen};

fn main() {
    let config = Config::builder()
        .dbc_name("example.dbc")
        .dbc_content(include_bytes!("../testing/dbc-examples/example.dbc"))
        //.impl_arbitrary(FeatureConfig::Gated("arbitrary")) // optional
        //.impl_debug(FeatureConfig::Always)                 // optional
        .build();

    let mut out = Vec::<u8>::new();
    codegen(config, &mut out).unwrap();
}

fn gen() {
}
