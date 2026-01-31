use constants.nu *

def --env setup_artifacts []: nothing -> string {
  let dir = mktemp -d -t bootstrap-XXXXXX | str trim
  $env.ARTIFACTS = $dir;
  $dir
}

export def --env artifacts []: nothing -> string {
  let arts = $env.ARTIFACTS?
  if not ($arts == null) {
    return $arts
  }
  setup_artifacts
}


export def user []: nothing -> string {
  nix eval --raw -f $VARS_DIR username
}

export def --env ssh_with_opts [command: string, user: string, host: string, known_hosts_file:string = ""]: nothing -> nothing {
  
  if not ($known_hosts_file == "") {
    ssh -t -o UserKnownHostsFile=($known_hosts_file) -o ConnectTimeout=10 -o ControlMaster=auto -o $"ControlPath=(artifacts)/ssh-%r@%h:%p" -o ControlPersist=10m $"($user)@($host)" $command
  } else {
    ssh -t  -o ConnectTimeout=10 -o ControlMaster=auto -o $"ControlPath=(artifacts)/ssh-%r@%h:%p" -o ControlPersist=10m $"($user)@($host)" $command
  }

}

export def --env scp_with_opts [infile: string, outfile: string, known_hosts_file: string = ""]: nothing -> nothing {
  if not ($known_hosts_file == "") {
    scp  -o UserKnownHostsFile=($known_hosts_file) -o ConnectTimeout=10 -o ControlMaster=auto -o $"ControlPath=(artifacts)/ssh-%r@%h:%p" -o ControlPersist=10m $infile $outfile
  } else {
    scp -o ConnectTimeout=10 -o ControlMaster=auto -o $"ControlPath=(artifacts)/ssh-%r@%h:%p" -o ControlPersist=10m $infile $outfile
  }
}

export def --env scp_down [infile: string, outfile: string, user: string, host: string, known_hosts_file: string = ""]: nothing -> nothing {
  scp_with_opts $"($user)@($host):($infile)" $outfile  $known_hosts_file
}

export def --env scp_up [infile: string, outfile: string, user: string, host: string, known_hosts_file: string = ""]: nothing -> nothing {
  scp_with_opts $infile $"($user)@($host):($outfile)"   $known_hosts_file
}

export def prompt_key_local []: nothing -> nothing {
    print ""
    print "=================================================================="
    print " 🔌  ACTION REQUIRED: YUBIKEY -> LOCAL "
    print "=================================================================="
    print "Please plug your YubiKey into THIS machine (Local)."
    print "Needed for: SSH Authentication / File Transfer"
    print "------------------------------------------------------------------"
    input "Press [Enter] when the key is connected locally..."
}

export def prompt_key_remote [host: string]: nothing -> nothing {
    print ""
    print "=================================================================="
    print $" 🔌  ACTION REQUIRED: YUBIKEY -> REMOTE ({host})"
    print "=================================================================="
    print "Please plug your YubiKey into the TARGET machine."
    print "Needed for: Identity Attestation (Decryption)"
    print "------------------------------------------------------------------"
    input "Press [Enter] when the key is connected remotely..."
}
