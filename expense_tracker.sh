#!/bin/bash

FILE="expenses.csv"

# Create CSV file if it doesn't exist
if [ ! -f "$FILE" ]; then
    echo "Date,Amount,Category,Description" > "$FILE"
fi

# -------------------------
# FUNCTION: ADD EXPENSE
# -------------------------
add_expense() {
    amount=$(gum input --placeholder "Enter amount")
    category=$(gum input --placeholder "Enter category (Food/Travel/Bills/etc.)")
    description=$(gum input --placeholder "Enter description")
    date=$(date +"%Y-%m-%d")

    echo "$date,$amount,$category,$description" >> "$FILE"
    gum style --foreground 10 --bold "✔ Expense added successfully!"
}

# -------------------------
# FUNCTION: VIEW EXPENSES
# -------------------------
view_expenses() {
    gum table --separator="," < "$FILE"
}

# -------------------------
# FUNCTION: SEARCH EXPENSES
# -------------------------
search_expenses() {
    field=$(gum choose "date" "amount" "category" "description")
    term=$(gum input --placeholder "Enter search term")

    gum style --foreground 4 --bold "🔍 Search Results:"
    grep -i "$term" "$FILE" | gum table --separator=","
}

# -------------------------
# FUNCTION: GENERATE REPORT
# -------------------------
generate_report() {
    gum style --foreground 6 --bold "📊 Expense Summary"

    total=$(awk -F',' 'NR>1 {sum+=$2} END {print sum}' "$FILE")
    avg=$(awk -F',' 'NR>1 {sum+=$2; count++} END {if(count>0) print sum/count; else print 0}' "$FILE")

    gum style --bold "Total Expense: ₹$total"
    gum style --bold "Average Daily: ₹$avg"

    gum style --foreground 3 --bold "📌 Category Breakdown:"
    awk -F',' 'NR>1 {cat[$3]+=$2} END {for (c in cat) print c "," cat[c]}' "$FILE" \
    | gum table --separator=","
}

# -------------------------
# FUNCTION: DELETE EXPENSE
# -------------------------
delete_expense() {
    gum style --foreground 1 --bold "Select an entry to delete:"

    entry=$(gum choose $(tail -n +2 "$FILE"))
    [ -z "$entry" ] && return

    line=$(grep -nF "$entry" "$FILE" | cut -d: -f1)

    if gum confirm "Are you sure?"; then
        sed -i "${line}d" "$FILE"
        gum style --foreground 1 --bold "❌ Entry deleted!"
    else
        gum style "Cancelled."
    fi
}

# -------------------------
# FUNCTION: EDIT EXPENSE
# -------------------------
edit_expense() {
    gum style --foreground 2 --bold "Select an entry to edit:"

    entry=$(gum choose $(tail -n +2 "$FILE"))
    [ -z "$entry" ] && return

    line=$(grep -nF "$entry" "$FILE" | cut -d: -f1)

    IFS=',' read -r old_date old_amount old_cat old_desc <<< "$entry"

    new_amount=$(gum input --placeholder "Amount ($old_amount)")
    new_category=$(gum input --placeholder "Category ($old_cat)")
    new_desc=$(gum input --placeholder "Description ($old_desc)")

    new_amount=${new_amount:-$old_amount}
    new_category=${new_category:-$old_cat}
    new_desc=${new_desc:-$old_desc}

    new_line="$old_date,$new_amount,$new_category,$new_desc"

    sed -i "${line}s/.*/$new_line/" "$FILE"

    gum style --foreground 2 --bold "✔ Entry updated!"
}

# -------------------------
# MAIN MENU
# -------------------------
while true; do
    choice=$(gum choose \
        "Add Expense" \
        "View Expenses" \
        "Search Expenses" \
        "Generate Report" \
        "Edit Expense" \
        "Delete Expense" \
        "Exit")

    case "$choice" in
        "Add Expense") add_expense ;;
        "View Expenses") view_expenses ;;
        "Search Expenses") search_expenses ;;
        "Generate Report") generate_report ;;
        "Edit Expense") edit_expense ;;
        "Delete Expense") delete_expense ;;
        "Exit") gum style --bold "👋 Goodbye!"; exit ;;
    esac
done
