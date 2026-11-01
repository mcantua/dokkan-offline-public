pub mod bundle;
mod control;
pub mod error;
pub mod macho;
pub mod provisioning;
pub mod rustcrypto_cms;
pub mod signature;

pub use bundle::{Bundle, BundleSigningSettings, CodeResourcesMaps, sign_bundle, sign_bundle_controlled};
pub use error::{CodeSignError, Result};
pub use control::StopPredicate;
pub use macho::{
    DEFAULT_CMS_BLOB_RESERVATION, MachOSigningConfig, sign_macho_data, sign_macho_file,
    sign_macho_file_controlled,
};
pub use provisioning::ProvisioningProfile;
pub use rustcrypto_cms::RustCryptoCmsSigner;
pub use signature::{CmsSigner, CmsSigningRequest, EncodedCodeDirectory, HashAlgorithm};
