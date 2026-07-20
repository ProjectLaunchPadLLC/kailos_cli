gc_push_file() {
    FILE="$1"
    REMOVE_AFTER="$2"   # this will be "-r" if used

    if [ -z "$FILE" ]; then
        echo "Usage: gc push file <filename> [-r]"
        return
    fi

    if [ ! -f "$FILE" ]; then
        echo "File not found: $FILE"
        return
    fi

    if [ ! -f "$HOME/.gitconnect-current-repo" ]; then
        echo "No repo connected. Use 'gc link repo' first."
        return
    fi

    CONNECTED_REPO=$(cat "$HOME/.gitconnect-current-repo")

    echo "Fetching directory list from $CONNECTED_REPO..."
    DIRS=$(gh api repos/$CONNECTED_REPO/contents --jq '.[] | select(.type=="dir") | .path')

    echo
    echo "Select destination directory:"
    echo "1) / (root)"

    i=2
    declare -A DIR_MAP
    DIR_MAP[1]="/"

    for dir in $DIRS; do
        echo "$i) $dir/"
        DIR_MAP[$i]="$dir"
        ((i++))
    done

    echo "$i) Create new directory"
    NEW_OPTION=$i

    echo
    read -p "Enter number: " CHOICE

    if [ "$CHOICE" = "$NEW_OPTION" ]; then
        read -p "Enter new directory name: " NEW_DIR
        DEST="$NEW_DIR"
    else
        DEST=${DIR_MAP[$CHOICE]}
    fi

    if [ -z "$DEST" ]; then
        echo "Invalid selection."
        return
    fi

    echo "Uploading $FILE to $CONNECTED_REPO at $DEST..."

    BASE64_CONTENT=$(base64 < "$FILE")

    gh api \
        -X PUT \
        repos/$CONNECTED_REPO/contents/$DEST/$FILE \
        -f message="Add $FILE" \
        -f content="$BASE64_CONTENT"

    echo "File uploaded successfully."

    # -----------------------------
    # REMOVE LOCAL FILE IF "-r" USED
    # -----------------------------
    if [ "$REMOVE_AFTER" = "-r" ]; then
        echo "Removing local file: $FILE"
        rm "$FILE"
        echo "Local file removed."
    fi
}
