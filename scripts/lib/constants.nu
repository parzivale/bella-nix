export const YUBIKEY_PUB = path self | path join "../../src/common/secrets/yubikey_identity.pub" | path expand
export const BOOTSTRAP_HOSTNAME = "bootstrap.local"
export const PROJECT_ROOT = path self | "./" | path expand
export const HOSTS_DIR = $PROJECT_ROOT | path join src hosts
export const TEMPLATE_DIR = $PROJECT_ROOT | path join /template
export const VARS_DIR = $PROJECT_ROOT | path join vars.nix
