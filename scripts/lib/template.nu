use constants.nu *

export def main [target_hostname: string]: nothing -> nothing {
  let TARGET_DIR = $"($HOSTS_DIR)/($target_hostname)"
  mkdir $HOSTS_DIR
  cp -r $"($TEMPLATE_DIR)/host" $TARGET_DIR
}
