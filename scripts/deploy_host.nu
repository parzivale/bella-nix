use lib

export def main []: nothing -> nothing {
  let hostname: string =  ls -s $lib.HOSTS_DIR | get name | input list

  let domain = $"($hostname).(lib tailscale_domain)"
  
  deploy -i $domain
}
