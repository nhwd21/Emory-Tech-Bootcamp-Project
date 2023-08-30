# Import the argparse and mysql.connector modules.

import argparse
import mysql.connector
import csv
# Define the main function.
def main():
    # Parse the command-line arguments.
    parser = argparse.ArgumentParser(description="Download a table from MySQL and store it in a CSV file.")
    parser.add_argument("--columns", required=True, help="The names of the columns you want to select separated by comma")
    parser.add_argument("--table", required=True, help="The name of the table to download.")
    parser.add_argument("--csv", required=True, help="The name of the CSV file to store the table in.")
    args = parser.parse_args()
    # Connect to the MySQL database.
    print("Connect to the MySQL database........")
    connection = mysql.connector.connect(host="msba2024-serverless-mysql-production.cluster-cqxikovybdnm.us-east-2.rds.amazonaws.com", user="PIRADU3", password="HTYDgTxIGr", database="MSBA_Team9")
    # Get the table data.
    cursor = connection.cursor()
    #reading table...
    print("reading table.........")
    cursor.execute("SELECT {} FROM {}".format(args.columns, args.table))
    data = cursor.fetchall()
    column_names = [i[0] for i in cursor.description]

    # Write the table data to a CSV file.

    #download started
    print("download started.........")

    with open(args.csv, "w", newline='', encoding='utf-8') as f:

        #downloading... 
        print("downloading......")
        writer = csv.writer(f)

        writer.writerow(column_names)
        writer.writerows(data)
    # Close the connection to the MySQL database.
    cursor.close()
    connection.close()

    # File saved
    print("File saved.")

# Call the main function.
if __name__ == "__main__":
    main()