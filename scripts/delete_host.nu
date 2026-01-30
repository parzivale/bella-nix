use lib

export def main [target_hostname: string]: nothing -> nothing {
    let TARGET_DIR = $"($lib.HOSTS_DIR)/($target_hostname)"
   
    if (not ($TARGET_DIR | path exists)) {
        print $"==> Error: Host directory ($TARGET_DIR) doesn't exsist"
        exit 1
    }

    rm -r $TARGET_DIR
}
