rm  $1/.ssh/id_rsa.pub && touch  $1/.ssh/id_rsa.pub && rm  $1/.ssh/authorized_keys && touch  $1/.ssh/authorized_keys
for host in `cat $2/datas/datanode.list | uniq`
    do
        echo $host >>  $2/etc/hadoop/slaves
        echo $host >> /spark/conf/slaves
        echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDK4PCQdGfRQzBaOhctpyROhAHUu/Y5HtzVS3Y7UmYFoEot8cZ4eoGD3v3nR6FCu9jSAKoEvhpRH/iUod7yEIoaDLiUO0YQWlKw4n/IdGqfWUqkx5S6c1eLi83lWRCs5prWtxpYID5DPVu9G3r1uj/B7Rbv/I4Y3meywl8qzvI01MacRZyqBAHLfOOBqsYyH3UCLACXLeilMv2kRNRf+z0Desij2Qya3GDSqvoDlLi9tBVBifNT52A2+4i4/8UV/IFzb48jrPbugX/DQy3i6BDXsRfv3aTN1C4y2io15rdoTnCZeWb2VwSz61oCz5zcOuLGh8dkMRk7JRQaFTC+e8tf root@$host" >> $1/.ssh/id_rsa.pub
    done;
cat $1/.ssh/id_rsa.pub >> $1/.ssh/authorized_keys