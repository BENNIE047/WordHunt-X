#!/bin/bash

# Cool ASCII Banner
echo "
██╗    ██╗ ██████╗ ██████╗ ██████╗ ███████╗██╗███╗   ██╗██████╗ ███████╗██████╗ 
██║    ██║██╔═══██╗██╔══██╗██╔══██╗██╔════╝██║████╗  ██║██╔══██╗██╔════╝██╔══██╗
██║ █╗ ██║██║   ██║██████╔╝██║  ██║█████╗  ██║██╔██╗ ██║██║  ██║█████╗  ██████╔╝
██║███╗██║██║   ██║██╔══██╗██║  ██║██╔══╝  ██║██║╚██╗██║██║  ██║██╔══╝  ██╔══██╗
╚███╔███╔╝╚██████╔╝██║  ██║██████╔╝██║     ██║██║ ╚████║██████╔╝███████╗██║  ██║
 ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═══╝╚═════╝ ╚══════╝╚═╝  ╚═╝
                                                                                  
      🔍 System Word Finder v2.0 TURBO - Lightning Fast Search ⚡
"

# Get search word
read -p "📝 What word do you want to find? " WORD

# Validate input
if [ -z "$WORD" ]; then
    echo "❌ Error: Please enter a word to search!"
    exit 1
fi

# Get search location
echo
echo "Where should I search?"
echo "1) Your home folder (~)"
echo "2) Entire system (/)"
echo "3) Custom directory"
read -p "Choice (1/2/3): " CHOICE

case $CHOICE in
    1)
        DIR="$HOME"
        ;;
    2)
        DIR="/"
        echo "⚠️  WARNING: Searching entire system may take a while!"
        read -p "Continue? (y/n): " CONFIRM
        if [ "$CONFIRM" != "y" ]; then
            echo "❌ Cancelled."
            exit 0
        fi
        ;;
    3)
        read -p "📂 Enter directory path: " DIR
        ;;
    *)
        echo "❌ Invalid choice!"
        exit 1
        ;;
esac

# Validate directory
if [ ! -d "$DIR" ]; then
    echo "❌ Error: Directory '$DIR' does not exist!"
    exit 1
fi

# Search options
echo
read -p "🔤 Case-sensitive search? (y/n): " CASE

if [ "$CASE" = "y" ]; then
    CASE_FLAG=""
else
    CASE_FLAG="-i"
fi

# Show summary
echo
echo "════════════════════════════════"
echo "🔍 Search Summary:"
echo "   Word: '$WORD'"
echo "   Location: $DIR"
echo "   Case-sensitive: $CASE"
echo "════════════════════════════════"
echo
read -p "⚡ Start search? (y/n): " START

if [ "$START" != "y" ]; then
    echo "❌ Search cancelled."
    exit 0
fi

echo
echo "🔍 Searching... Please wait..."
echo

# Perform search and save to temporary file (OPTIMIZED FOR SPEED)
TEMP_FILE="/tmp/search_results_$"

# Use parallel processing with xargs for MASSIVE speed boost
# Skip binary files, limit to text files only for faster results
find "$DIR" -type f -name "*.txt" -o -name "*.sh" -o -name "*.log" -o -name "*.conf" -o -name "*.md" 2>/dev/null | \
    xargs -P 4 grep -l $CASE_FLAG "$WORD" 2>/dev/null > "$TEMP_FILE" &

# If user wants ALL files (slower but comprehensive)
# Uncomment this and comment above for full search:
# grep -rl $CASE_FLAG "$WORD" "$DIR" 2>/dev/null > "$TEMP_FILE" &

SEARCH_PID=$!

# Show progress spinner while searching
spin='-\|/'
i=0
while kill -0 $SEARCH_PID 2>/dev/null; do
    i=$(( (i+1) %4 ))
    printf "\r🔍 Searching... ${spin:$i:1}"
    sleep 0.1
done
printf "\r🔍 Searching... ✅ Done!     \n"
echo

# Check exit code
if [ $? -eq 0 ] && [ -s "$TEMP_FILE" ]; then
    # Count results
    COUNT=$(wc -l < "$TEMP_FILE")
    
    echo "════════════════════════════════"
    echo "✅ SUCCESS!"
    echo "════════════════════════════════"
    echo "📊 Found '$WORD' in $COUNT files"
    echo
    echo "📁 Files containing '$WORD':"
    echo "════════════════════════════════"
    
    # Show results with line numbers
    cat -n "$TEMP_FILE"
    
    echo "════════════════════════════════"
    echo
    
    # Ask if user wants to see file contents
    read -p "👁️  View contents of a file? (y/n): " VIEW
    
    if [ "$VIEW" = "y" ]; then
        read -p "Enter file number to view: " NUM
        FILE=$(sed -n "${NUM}p" "$TEMP_FILE")
        
        if [ -f "$FILE" ]; then
            echo
            echo "════════════════════════════════"
            echo "📄 Contents of: $FILE"
            echo "════════════════════════════════"
            grep --color=always -n $CASE_FLAG "$WORD" "$FILE"
        else
            echo "❌ Invalid file number!"
        fi
    fi
    
    # Cleanup
    rm -f "$TEMP_FILE"
    exit 0
else
    echo "════════════════════════════════"
    echo "❌ NO RESULTS"
    echo "════════════════════════════════"
    echo "No files containing '$WORD' were found in $DIR"
    
    # Cleanup
    rm -f "$TEMP_FILE"
    exit 1
fi
