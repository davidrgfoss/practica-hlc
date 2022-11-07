#!/usr/bin/env bash

QTH="$(dirname "${BASH_SOURCE[0]}")"
cd "$QTH"

function Generar {
    if [ -f "$HOME/.ssh/id_rsa" ]
    then
        BUCL1="n"
        while [ "$BUCL1" = "n" ]
        do
            clear
            echo -e "\n-------------------------------------------------------------------\n"
            echo -e "Se ha detectado una clave existente en $HOME/.ssh/id_rsa"
            echo -e "1. Usar esta clave copiandola a la maquina"
            echo -e "2. Generar otra nueva"
            read -e -n 1 Clave
            case "$Clave"
            in
            "1")
                sshpass -p 1 ssh-copy-id $IP
                BUCL1="s"
            ;;
            "2")
                BUCL2="n"
                Ruta="$HOME/pr-hlc"
                while [ "$BUCL2" = "n" ]
                do
                    clear
                    echo -e "Por defecto se creara una nueva clave en $HOME/pr-hlc/id_rsa"
                    echo -e "Si quieres escribir una ruta existente puedes hacerlo escribiendo una ruta absoluta"
                    echo -e "1. Ruta por defecto"
                    echo -e "2. Ruta definida por usuario"
                    read -e -n 1 OPRuta
                    case "$OPRuta"
                    in
                    "1")
                        mkdir "$HOME/pr-hlc"
                        ssh-keygen -t rsa -N "" -f $Ruta/id_rsa
                        sshpass -p 1 ssh-copy-id -i $Ruta/id_rsa.pub $IP
                        BUCL2="s"
                    ;;
                    "2")
                        echo -e "Escribe la ruta absoluta que exista sin errores, no sera comprobada"
                        read -e -p "=> " Ruta
                        ssh-keygen -t rsa -N "" -f $Ruta/id_rsa
                        sshpass -p 1 ssh-copy-id -i $Ruta/id_rsa.pub $IP
                        BUCL2="s"
                    ;;
                    *)
                    ;;
                    esac
                done
            ;;
            *)
            ;;
            esac
        done
    else
        BUCL2="n"
        Ruta="$HOME/pr-hlc"
        while [ "$BUCL2" = "n" ]
        do
            clear
            echo -e "\n-------------------------------------------------------------------\n"
            echo -e "No se ha detectado ninguna clave en $HOME/.ssh/"
            echo -e "Por defecto se creara una nueva clave en $HOME/pr-hlc/id_rsa"
            echo -e "Si quieres escribir una ruta existente puedes hacerlo escribiendo una ruta absoluta"
            echo -e "1. Ruta por defecto"
            echo -e "2. Ruta definida por usuario"
            read -e -n 1 OPRuta
            case "$OPRuta"
            in
            "1")
                mkdir "$HOME/pr-hlc"
                ssh-keygen -t rsa -N "" -f $Ruta/id_rsa
                sshpass -p 1 ssh-copy-id -i $Ruta/id_rsa.pub $IP
                BUCL2="s"
            ;;
            "2")
                echo -e "Escribe la ruta absoluta que exista sin errores, no sera comprobada"
                read -e -p "=> " Ruta
                ssh-keygen -t rsa -N "" -f $Ruta/id_rsa
                sshpass -p 1 ssh-copy-id -i $Ruta/id_rsa.pub $IP
                BUCL2="s"
            ;;
            *)
            ;;
            esac
        done
    fi
    Apache
}

function SSH {
	BUCL="n"
	while [ "$BUCL" = "n" ]
	do
		clear
		echo -e "Puedes escoger en copiar una clave existente a la maquina o crearla antes de copiarla. Tambien puedes usar la proporcionada"
		echo -e "-------------------------------------------------------------------"
		echo -e "1. Usar clave no integrada dentro de la imagen"
		echo -e "2. Usar clave integrada en la imagen"
		read -e -n 1 OPCMMP
		case "$OPCMMP"
		in
		"1")
            BUCL="s"
			Generar
		;;
		"2")
            Ruta="$QTH/id_rsa"
            BUCL="s"
            Apache
		;;
		*)
		;;
		esac
	done

}


function Terminos {
    BUCLSTART="n"
    while [ "$BUCLSTART" = "n" ]
    do
        clear
        echo -e "En este script se realizara las siguientes tareas\n1. Crear una imagen a partir de bullseye-base de 5GB en el directorio actual ($QTH)"
        echo -e "2. Crear una red interna de nombre intra con red 10.10.20.0/24"
        echo -e "3. Crear una maquina llamada maquina1 y modificar su hostname"
        echo -e "4. Crear un volumen adicional de 1GB con formato RAW\n5. Dar formato XFS a dicho volumen y montarlo en el directorio /var/www/html"
        echo -e "6. Instalaremos en la maquina apache2 y copiaremos un fichero index.html"
        echo -e "7. Instalaremos LXC y creamos un container\n8. Añadiremos la interfaz br0 a la maquina."
        echo -e "9. Aumentamos a 2GB de RAM la maquina\n10. Crearemos un snapshot de ella"
        echo -e "Continuamos con el script (s/n)"
        read -e -n 1 Condiciones
        case "$Condiciones"
        in
        "s")
            BUCLSTART="s"
            CrearMaquina
        ;;
        "n")
            BUCLSTART="s"
            echo -e "Hasta luego"
        ;;
        *)
        ;;
        esac
    done
}

function CrearMaquina {
    BUCL="n"
    while [ "$BUCL" = "n" ]
    do
        clear
        echo -e "Escribe un nombre para la maquina"
        read -e -p "=> " NombreMaquina
        comp1=`virsh list --all | tail +3 | grep "wordpress" | xargs | cut -d " " -f 2`
        if [ "$NombreMaquina" = "$comp1" ]
        then
            echo -e "La maquina ya existe"
            sleep 5
        else
            echo -e "Creando volumen y redimensionando"
            virsh vol-create-as --capacity 5G --format qcow2 --pool default --backing-vol "bullseye-base.qcow2" --name "$NombreMaquina.qcow2" --backing-vol-format qcow2
            sleep 3
            sudo qemu-img create -f qcow2 "/tmp/$NombreMaquina.qcow2" 5G
            sleep 3
            sudo virt-resize --expand /dev/vda1 "/var/lib/libvirt/images/$NombreMaquina.qcow2" "/tmp/$NombreMaquina.qcow2"
            sleep 3
            sudo mv -f "/tmp/$NombreMaquina.qcow2" "/var/lib/libvirt/images/$NombreMaquina.qcow2"
            sleep 3
            virsh vol-create-as --pool default --name vol28 --capacity 1G --format raw
            BUCL="s"
            sleep 10
        fi
    done
    echo -e "-------------------------------------------------------------------"
    echo -e "Crear Red intra"
	echo -e "-------------------------------------------------------------------\n"
    echo -e "<network>\n<name>intra</name>\n<bridge name='virbr28'/>\n<forward/>\n<ip address='10.10.20.1' netmask='255.255.255.0'>\n\t<dhcp>\n\t\t<range start='10.10.20.2' end='10.10.20.254'/>\n\t</dhcp>\n</ip>\n</network>" > intra.xml
    virsh net-define ./intra.xml && virsh net-start intra && virsh net-autostart intra
    rm -Rf ./intra.xml
    echo -e "-------------------------------------------------------------------"
    echo -e "Crear Maquina"
	echo -e "-------------------------------------------------------------------\n"
    virt-install \
    --virt-type kvm \
    --name $Maquina \
    --os-variant debian11 \
    --disk path="/var/lib/libvirt/images/$NombreMaquina.qcow2" \
    --import \
    --network network=intra \
    --memory 1024 \
    --vcpus 1 \
    --noautoconsole
    virsh attach-disk "$NombreMaquina" /var/lib/libvirt/images/vol1 vdb --driver=qemu --type disk --subdriver raw --persistent
    sudo virt-sysprep -d "$NombreMaquina" --hostname "$NombreMaquina"
    SSH
    echo -e "-------------------------------------------------------------------"
    echo -e "Crear Contenedor y añadiendo interfaz br0"
	echo -e "-------------------------------------------------------------------\n"
    sudo lxc-create -n hlc2 -t ubuntu -- -r jammy
    virsh shutdown "$NombreMaquina"
    virsh attach-interface $NombreMaquina bridge br0 --model virtio --persistent --config
    virsh start "$NombreMaquina"
    ssh -i "$Ruta" "$Connect" "ip a"
    sleep 10
    echo -e "-------------------------------------------------------------------"
    echo -e "Cambiar RAM y crear snapshot"
	echo -e "-------------------------------------------------------------------\n"
    virsh shutdown "$NombreMaquina"
    virsh setmaxmem --size 3G --domain "$NombreMaquina" --config
    virsh setmem --domain "$NombreMaquina" --size 2G
    echo -e "-------------------------------------------------------------------"
    echo -e "Creando Snapshot"
	echo -e "-------------------------------------------------------------------\n"
    snapshot-create-as "$NombreMaquina" --name Practica --description "Pratica" --atomic
}

function Apache {
    echo -e "-------------------------------------------------------------------"
    echo -e "Configurar apache"
	echo -e "-------------------------------------------------------------------\n"
    host=`virsh net-dhcp-leases default | tail +3 | grep "$NombreMaquina" | xargs | cut -d " " -f 5 | cut -d "/" -f 1`
    Connect="debian@$host"
    ssh -i "$Ruta" "$Connect" -o "StrictHostKeyChecking no" "sudo apt install xfsprogs apache2 lxc lxc-templates -y && rm -f /var/www/html/index.html"
    ssh -i "$Ruta" "$Connect" "(echo o; echo n; echo p; echo -e "\n"; echo "\n"; echo "\n"; echo w) | fdisk /dev/vdb && mkfs.xfs /dev/vdb1"
    ssh -i "$Ruta" "$Connect" "sudo mount /dev/vdb1 /var/www/html"
    ssh -i "$Ruta" "$Connect" 'sudo echo -e "`blkid | grep "/dev/mapper/Sistema-var" | cut -d " " -f 2 | xargs`  /var/www/html  xfs  defaults  0  0"'
    scp -i "$Ruta" index.html "$Connect:/home/debian"
    ssh -i "$Ruta" "$Connect" "sudo mv /home/debian/index.html /var/www/html && sudo chown -Rf www-data:www-data /var/www/* && ip a"
    echo -e "Continuar? (Pulsa cualquier tecla)"
    read -e -n 1 aux
}


if [ "$#" -eq "0" ]
then
	CrearMaquina
else
	clear
	echo -e "Este script no permite ejecutarse con argumentos."
fi