#!/bin/bash

# Fonction pour afficher les instructions d'installation
display_install_instructions() {
    if [ "$LANGUAGE" = "fr" ]; then
        echo "Node.js et npm ne sont pas installés."
        echo "Pour les installer, veuillez exécuter les commandes suivantes :"
        echo "curl -sL https://deb.nodesource.com/setup_14.x -o nodesource_setup.sh"
        echo "sudo bash nodesource_setup.sh"
        echo "sudo apt install nodejs"
    else
        echo "Node.js and npm are not installed."
        echo "To install them, please run the following commands:"
        echo "curl -sL https://deb.nodesource.com/setup_14.x -o nodesource_setup.sh"
        echo "sudo bash nodesource_setup.sh"
        echo "sudo apt install nodejs"
    fi
    exit 1
}

# Fonction pour télécharger, déplacer les fichiers et configurer le service
install_and_setup() {
    VERSION_URL="https://mirror.chtrg.fr/github/nginx/nginx-proxy-api/sh-ver/$1/"
    DEST_DIR="/etc/api-nginxproxy"
    
    # Créer le répertoire s'il n'existe pas
    if [ ! -d "$DEST_DIR" ]; then
        if [ "$LANGUAGE" = "fr" ]; then
            echo "Création du répertoire ${DEST_DIR}..."
        else
            echo "Creating directory ${DEST_DIR}..."
        fi
        sudo mkdir -p "$DEST_DIR"
        if [ $? -eq 0 ]; then
            if [ "$LANGUAGE" = "fr" ]; then
                echo "Répertoire ${DEST_DIR} créé avec succès."
            else
                echo "Directory ${DEST_DIR} created successfully."
            fi
        else
            if [ "$LANGUAGE" = "fr" ]; then
                echo "Erreur lors de la création du répertoire ${DEST_DIR}."
            else
                echo "Error creating directory ${DEST_DIR}."
            fi
            exit 1
        fi
    fi

    if [ "$LANGUAGE" = "fr" ]; then
        echo "Téléchargement des fichiers pour $1..."
    else
        echo "Downloading files for $1..."
    fi
    
    # Télécharger les fichiers
    wget "${VERSION_URL}server.js" -O "${DEST_DIR}/server.js"
    wget "${VERSION_URL}package.json" -O "${DEST_DIR}/package.json"
    
    if [ $? -eq 0 ]; then
        if [ "$LANGUAGE" = "fr" ]; then
            echo "Fichiers téléchargés avec succès."
        else
            echo "Files downloaded successfully."
        fi
    else
        if [ "$LANGUAGE" = "fr" ]; then
            echo "Erreur lors du téléchargement des fichiers."
        else
            echo "Error downloading files."
        fi
        exit 1
    fi

    if [ "$LANGUAGE" = "fr" ]; then
        echo "Déplacement des fichiers dans ${DEST_DIR}."
    else
        echo "Moving files to ${DEST_DIR}."
    fi

    # Exécuter npm install
    if [ "$LANGUAGE" = "fr" ]; then
        echo "Exécution de npm install dans ${DEST_DIR}..."
    else
        echo "Running npm install in ${DEST_DIR}..."
    fi
    sudo npm install --prefix "$DEST_DIR"
    
    if [ $? -eq 0 ]; then
        # Installation terminée avec succès, ne pas afficher de message
        true
    else
        if [ "$LANGUAGE" = "fr" ]; then
            echo "Erreur lors de l'installation des dépendances."
        else
            echo "Error installing dependencies."
        fi
        exit 1
    fi

    # Création du fichier .service
    NODE_PATH=$(which node)
    SERVICE_FILE="/etc/systemd/system/nginx-proxy-api.service"

    if [ "$LANGUAGE" = "fr" ]; then
        echo "Création du fichier de service systemd..."
    else
        echo "Creating systemd service file..."
    fi
    sudo bash -c "cat > $SERVICE_FILE << EOF
[Unit]
Description=Nginx Proxy API Service
After=network.target

[Service]
ExecStart=${NODE_PATH} /etc/api-nginxproxy/server.js
WorkingDirectory=/etc/api-nginxproxy
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF"

    if [ $? -eq 0 ]; then
        if [ "$LANGUAGE" = "fr" ]; then
            echo "Fichier de service systemd créé avec succès : $SERVICE_FILE"
        else
            echo "Systemd service file created successfully: $SERVICE_FILE"
        fi
    else
        if [ "$LANGUAGE" = "fr" ]; then
            echo "Erreur lors de la création du fichier de service systemd."
        else
            echo "Error creating systemd service file."
        fi
        exit 1
    fi
    
    if [ "$LANGUAGE" = "fr" ]; then
        echo "Rechargement des services systemd..."
    else
        echo "Reloading systemd services..."
    fi
    sudo systemctl daemon-reload
    if [ $? -eq 0 ]; then
        if [ "$LANGUAGE" = "fr" ]; then
            echo "Services systemd rechargés avec succès."
        else
            echo "Systemd services reloaded successfully."
        fi
    else
        if [ "$LANGUAGE" = "fr" ]; then
            echo "Erreur lors du rechargement des services systemd."
        else
            echo "Error reloading systemd services."
        fi
        exit 1
    fi

    if [ "$LANGUAGE" = "fr" ]; then
        echo "Activation du service pour démarrage automatique au boot..."
    else
        echo "Enabling service for automatic startup on boot..."
    fi
    sudo systemctl enable nginx-proxy-api
    if [ $? -eq 0 ]; then
        if [ "$LANGUAGE" = "fr" ]; then
            echo "Service activé pour démarrage automatique avec succès."
        else
            echo "Service enabled for automatic startup successfully."
        fi
    else
        if [ "$LANGUAGE" = "fr" ]; then
            echo "Erreur lors de l'activation du service."
        else
            echo "Error enabling service."
        fi
        exit 1
    fi

    if [ "$LANGUAGE" = "fr" ]; then
        echo "Démarrage du service..."
    else
        echo "Starting the service..."
    fi
    sudo systemctl start nginx-proxy-api
    if [ $? -eq 0 ]; then
        if [ "$LANGUAGE" = "fr" ]; then
            echo "Service démarré avec succès."
        else
            echo "Service started successfully."
        fi
    else
        if [ "$LANGUAGE" = "fr" ]; then
            echo "Erreur lors du démarrage du service."
        else
            echo "Error starting the service."
        fi
        exit 1
    fi
}

# Fonction pour vérifier si le port 3000 est libre
check_port() {
    PORT=3000
    if sudo lsof -i:$PORT &> /dev/null; then
        if [ "$LANGUAGE" = "fr" ]; then
            echo "Le port $PORT est déjà utilisé. Veuillez libérer le port avant de continuer."
        else
            echo "Port $PORT is already in use. Please free up the port before proceeding."
        fi
        exit 1
    fi
}

# Fonction pour vérifier si Node.js et npm sont installés
check_node_npm() {
    if ! command -v node &> /dev/null; then
        display_install_instructions
    fi

    if ! command -v npm &> /dev/null; then
        display_install_instructions
    fi
}

# Sélection de la langue
echo "Select your language / Choisissez votre langue:"
options=("English" "Français")
select lang in "${options[@]}"
do
    case $lang in
        "English")
            LANGUAGE="en"
            break
            ;;
        "Français")
            LANGUAGE="fr"
            break
            ;;
        *)
            if [ "$LANGUAGE" = "fr" ]; then
                echo "Option invalide. Veuillez choisir un numéro valide."
            else
                echo "Invalid option. Please choose a valid number."
            fi
            ;;
    esac
done

# Vérifier si Node.js et npm sont installés
check_node_npm

# Vérification du port
check_port

# Demande de confirmation avant de continuer
if [ "$LANGUAGE" = "fr" ]; then
    echo "Le port 3000 doit être libre pour que l'application fonctionne correctement."
    echo "Vous allez maintenant télécharger et installer les fichiers. Voulez-vous continuer ? (oui/non)"
else
    echo "Port 3000 must be free for the application to work correctly."
    echo "You are about to download and install the files. Do you want to continue? (yes/no)"
fi

read -r CONFIRMATION
if [[ "$CONFIRMATION" != "oui" && "$CONFIRMATION" != "yes" ]]; then
    if [ "$LANGUAGE" = "fr" ]; then
        echo "Installation annulée."
    else
        echo "Installation canceled."
    fi
    exit 0
fi

# Sélection de la version
if [ "$LANGUAGE" = "fr" ]; then
    echo "Sélectionnez une version:"
else
    echo "Select a version:"
fi

select VERSION in "beta_1.0" "beta_2.0" "beta_3.0"
do
    case $VERSION in
        "beta_1.0"|"beta_2.0"|"beta_3.0")
            install_and_setup "$VERSION"
            break
            ;;
        *)
            if [ "$LANGUAGE" = "fr" ]; then
                echo "Option invalide. Veuillez choisir une version valide."
            else
                echo "Invalid option. Please choose a valid version."
            fi
            ;;
    esac
done

# Finalisation
exit 0
