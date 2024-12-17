import requests
from bs4 import BeautifulSoup
import pandas as pd
import csv
import re



def scrape_traffic_rules():
    rules = []

    url = "https://vodiy.ua/dai/penalty"
    print('Scraping URL:', url)

    response = requests.get(url)
    response.raise_for_status()  # Ensure successful request

    soup = BeautifulSoup(response.text, "html.parser")

    # Select all list items inside the penalty list (ul.dai-penalty_ul)
    elements = soup.select("ul.dai-penalty_ul > li")
    
    # Process each element to extract required data
    for element in elements:
        article_text = element.select_one(".left_panalty").get_text(strip=True)
        sup_text = element.select_one(".left_panalty sup").get_text(strip=True) if element.select_one(".left_panalty sup") else None
        penalty_fee = element.select_one(".right_panalty").get_text(strip=True).replace("грн", "").strip()
        description = element.select_one("p").get_text(strip=True)

        # Use regex to extract the article number (numeric part)
        article_match = re.match(r"(\d+)", article_text)  # Capture the number part of the article (e.g., '121')
        article = int(article_match.group(1)) if article_match else None
        
        # Extract the sup value (if available)
        sup = int(sup_text) if sup_text else None

        # Extract the part (e.g., 'ч.1')
        part_match = re.search(r"(ч\.\s*\d+)", article_text)  # Capture part like 'ч.1', 'ч.2', etc.
        part = part_match.group(0) if part_match else None

        # Clean the penalty_fee string and convert it to float
        penalty_fee = re.sub(r"[^\d.]", "", penalty_fee)  # Remove any non-numeric characters except '.'
        penalty_fee = float(penalty_fee) if penalty_fee else None
        
        # Append the rule to the list if valid
        rules.append({
            'article': article,
            'sup': sup,
            'part': part,
            'penalty_fee': penalty_fee,
            'description': description
        })

    # Return the list of rules
    return rules
# Step 2: Save rules to a CSV file
def save_to_csv(rules):
    with open("administrative_offenses.csv", "w", newline="", encoding="utf-8") as csvfile:
        fieldnames = ['article', 'sup', 'part', 'penalty_fee', 'description']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)

        writer.writeheader()  # Write column headers
        writer.writerows(rules)  # Write rows of rules data

        print(f"Saved {len(rules)} rules to ./course_work/csv/administrative_offenses.csv")
    
if __name__ == "__main__":
    # Step 1: Scrape the rules
    # print("Scraping traffic rules...")
    traffic_rules = scrape_traffic_rules()
    
    print(traffic_rules[0])

    # Step 2: Save to CSV
    save_to_csv(traffic_rules)