#!/bin/bash

LOG_FILE="logs/actions.log"

# Colors
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

log_action() {
    # "DATE" "ACTION" "USERNAME" "STATUS" "MESSAGE"
    local action="$1"
    local user="$2"
    local status="$3"
    local message="$4"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $action $user $status $message" >> "$LOG_FILE"
}

# Check for root access

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi


create_user(){

    read -p "Enter new username: " username

    # check if user already exists

    if id "$username" &>/dev/null; then
        echo "Error: User '$username' already exists."
        log_action "CREATE" "$username" "ERROR" "User already exists"
        return
    fi

    useradd "$username"

    if [ $? -ne 0 ]; then
        echo "Failed to create user '$username'."
        log_action "CREATE" "$username" "FAILED" "Failed to create user"
        return 
    fi

    echo "Set password for $username:"
    passwd "$username"
    
    if [ $? -ne 0 ]; then
        echo "User created but password not set properly."
        log_action "CREATE" "$username" "ISSUE" "Password not set properly"
    else
        echo "User '$username' created successfully."
        log_action "CREATE" "$username" "SUCCESS" "User created successfully"
    fi
}

delete_user() {
    
    read -p "Enter username to delete: " username

    # check if user exists
    if ! id "$username" &>/dev/null; then
        echo "Error: User '$username' does not exist."
        log_action "DELETE" "$username" "ERROR" "User does not exist"
        return
    fi

    # confirm deletion
    read -p "Do you want to remove the user's home directory? (y/n): " confirm

    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        userdel -r "$username"
    else 
        userdel "$username"
    fi


    if [ $? -eq 0 ]; then
        echo "$username deleted successfully."
        log_action "DELETE" "$username" "SUCCESS" "User deleted"
    else
        echo "Failed to delete user '$username'."
        log_action "DELETE" "$username" "ERROR" "Failed to delete user"

    fi
}

list_users() {
    echo -e "\n===== User List with Status ====="
    printf "%-20s %-10s\n" "Username" "Status"
    echo "----------------------------------------"

    # Only show users with UID ≥ 1000 and < 65534 (normal users)
    awk -F: '$3 >= 1000 && $3 < 65534 { print $1 }' /etc/passwd | while read username; do
        status=$(passwd -S "$username" 2>/dev/null | awk '{print $2}')
        
        # Translate status code
        case "$status" in
            P) status_str="Active" ;;
            L) status_str="Locked" ;;
            NP) status_str="NoPassword" ;;
            *) status_str="Unknown" ;;
        esac

        printf "%-20s %-10s\n" "$username" "$status_str"
    done

    echo "----------------------------------------"
    log_action "LIST" "ALL" "INFO" "Listed all users with account status"
}


lock_user() {
    read -p "Enter username to lock: " username

    # check if user exists
    if ! id "$username" &>/dev/null; then
        echo "Error: User '$username' does not exist."
        log_action "LOCK" "$username" "ERROR" "User does not exist"
        return
    fi

    # lock the user
    passwd -l "$username"

    if [ $? -eq 0 ]; then
        echo "$username has been locked (disabled)."
        log_action "LOCK" "$username" "SUCCESS" "User locked"

    else 
        echo "Failed to lock user '$username'."
        log_action "LOCK" "$username" "ERROR" "Failed to lock user"

    fi

}

unlock_user() {
    read -p "Enter username to unlock: " username

    # check if user exists
    if ! id "$username" &>/dev/null; then
        echo "Error: User '$username' deos not exist."
        log_action "UNLOCK" "$username" "ERROR" "User does not exist"
        return
    fi

    # unlock the user
    passwd -u "$username"
    if [ $? -eq 0 ]; then
        echo "User '$username' has been unlocked (enabled)."
        log_action "UNLOCK" "$username" "SUCCESS" "User unlocked"
    else
        echo "Failed to unlock user '$username'."
        log_action "UNLOCK" "$username" "FAILED" "Failed to unlock user"
    fi

}

check_user() {
    read -p "Enter username to check: " username

    if id "$username" &>/dev/null; then
        echo "User '$username' exists on the system."
        log_action "CHECK" "$username" "FOUND" "User exists"
    else 
        echo "User '$username' does NOT exist."
        log_action "CHECK" "$username" "NOT_FOUND" "User does not exist"
    fi
}

reset_password() {
    read -p "Enter username to reset password: " username

    # check if user exists
    if ! id "$username" &>/dev/null; then
        echo "Error: User '$username' does not exist."
        log_action "RESET_PWD" "$username" "ERROR" "Password reset"
        return 
    fi

    echo "Set new password for '$username':"
    passwd "$username"

    if [ $? -eq 0 ]; then 
        echo "Password for '$username' has neem updated successfully."
        log_action "RESET_PWD" "$username" "SUCCESS" "Password reset"

    else
        echo "Failed to reset password for '$username'."
        log_action "RESET_PWD" "$username" "FAILED" "Failed to reset password"

    fi

}

exit_script() {
    echo "Exiting User Management Tool."
    exit 0
}

# Main Menu Loop
while true; do

    echo ""
    echo "========== User Management Tool =========="
    echo "1. Create User"
    echo "2. Delete User"
    echo "3. List All Users"
    echo "4. Lock User"
    echo "5. Unlock User"
    echo "6. Check if User Exists"
    echo "7. Reset User Password"
    echo "0. Exit"
    echo "=========================================="
    read -p "Enter your choice: " choice

    case "$choice" in
        1) create_user ;;
        2) delete_user ;;
        3) list_users ;;
        4) lock_user ;;
        5) unlock_user ;;
        6) check_user ;;
        7) reset_password ;;
        0) exit_script ;;
        *) echo "Invalid choice, try again." ;;
    esac
done