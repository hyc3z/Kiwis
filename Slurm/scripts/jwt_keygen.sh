openssl genrsa -out /var/spool/slurm/ctld/jwt_hs256.key 2048
chown slurm /var/spool/slurm/ctld/jwt_hs256.key
chmod 0600 /var/spool/slurm/ctld/jwt_hs256.key