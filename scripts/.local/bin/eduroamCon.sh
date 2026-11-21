#!/bin/bash
# Spajanje na eduroam (WPA2 Enterprise + TTLS + PAP) preko nmcli.
# Vjerodajnice se NE spremaju u repo: postavi EDUROAM_USER / EDUROAM_PASS
# ili ih unesi kad skripta pita.

USERNAME="${EDUROAM_USER:-}"
PASSWORD="${EDUROAM_PASS:-}"

[ -z "$USERNAME" ] && read -rp "eduroam korisnik (npr. ab12345@fer.hr): " USERNAME
[ -z "$PASSWORD" ] && { read -rsp "eduroam lozinka: " PASSWORD; echo; }

# Obrisi stari profil ako postoji (nije obavezno)
nmcli connection delete eduroam 2>/dev/null

# Kreiraj novi eduroam profil
nmcli connection add \
    type wifi \
    con-name "eduroam" \
    ifname "*" \
    ssid "eduroam"

# Postavi WPA2 Enterprise + TTLS + PAP
nmcli connection modify eduroam \
    wifi-sec.key-mgmt wpa-eap \
    802-1x.eap ttls \
    802-1x.phase2-auth pap \
    802-1x.identity "$USERNAME" \
    802-1x.password "$PASSWORD" \
    802-1x.anonymous-identity "" \
    802-1x.ca-cert "" \
    802-1x.system-ca-certs false

# Poveži se
nmcli connection up eduroam

echo "Pokušaj spajanja na eduroam je pokrenut."
