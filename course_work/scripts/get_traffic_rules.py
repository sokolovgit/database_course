import requests
from bs4 import BeautifulSoup
import pandas as pd
import csv




def scrape_traffic_rules():
    rules = []
    for i in range(1, 34):
        url = f"https://vodiy.ua/pdr/{i}"
        print('url:', url)
        
        response = requests.get(url)
        response.raise_for_status()  # Ensure successful request

        soup = BeautifulSoup(response.text, "html.parser")
        
        elements = soup.select("div.text_box")
        for element in elements:
            # Extract article and part from the "span.number > a" tag
            number_tag = element.select_one("span.number a")
            if number_tag:
                number_text = number_tag.text.strip()  # e.g., "1.1"
                article, part = map(int, number_text.split('.'))  # Convert to integers

                # Extract description text (cleaned)
                description_tags = element.select("p")
                description = " ".join([tag.get_text(strip=True) for tag in description_tags])

                # Append to rules list
                rules.append({
                    'article': article,
                    'part': part,
                    'description': description
                })
                
    return rules

# Step 2: Save rules to a CSV file
def save_to_csv(rules):
    with open("traffic_rules.csv", "w", newline="", encoding="utf-8") as csvfile:
        fieldnames = ['article', 'part', 'description']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)

        writer.writeheader()  # Write column headers
        writer.writerows(rules)  # Write rows of rules data

        print(f"Saved {len(rules)} rules to traffic_rules.csv")
    
if __name__ == "__main__":
    # Step 1: Scrape the rules
    # print("Scraping traffic rules...")
    traffic_rules = scrape_traffic_rules()
    
    print(traffic_rules[1])

    # Step 2: Save to CSV
    save_to_csv(traffic_rules)