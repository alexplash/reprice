import openai
import os
import sys
import re
import requests
from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

OPENAI_API_KEY = os.getenv('OPENAI_API_KEY')

def get_estimated_monthly_price(search_term, app_title, price_element):
  headers = {
    'Authorization': f'Bearer {OPENAI_API_KEY}',
    'Content-Type': 'application/json'
  }
  
  prompt = f"What is the estimated monthly price for the app with the given category '{search_term}', title '{app_title}', and a range of transaction prices within the string {price_element}? Consider common pricing models in this category and any factors that may affect the cost. Please provide a concise answer formatted with asterisks, like '...', to easily extract the data for my application."
  
  data = {
    'model': 'text-davinci-003',
    'prompt': prompt,
    'max_tokens': 100
  }
  
  try:
    response = requests.post('https://api.openai.com/v1/completions', headers=headers, json=data)
    if response.status_code == 200:
        return response.json()
    else:
        print(f"Error in API call: {response.status_code}")
        print("Response body:", response.text)
  except Exception as e:
    print(f"Exception during API call: {str(e)}")

BASE_URL = 'https://play.google.com'
SEARCH_TERM = 'planner'
SEARCH_URL = f'{BASE_URL}/store/search?q={SEARCH_TERM}&c=apps'

options = webdriver.ChromeOptions()
options.add_argument('headless')
driver = webdriver.Chrome(options=options)

driver.get(SEARCH_URL)

soup = BeautifulSoup(driver.page_source, 'html.parser')
app_links = [BASE_URL + a['href'] for a in soup.select('a.Si6A0c.Gy4nib')][:10]

results = []

for link in app_links:
    try:  
        driver.get(link)
        soup = BeautifulSoup(driver.page_source, 'html.parser')
        
        title_element = soup.select_one('h1[itemprop="name"]')
        rating_element = soup.select_one('div[aria-label^="Rated"]')
        
        app_title = title_element.text if title_element else None
        app_rating = float(rating_element['aria-label'].split()[1]) if rating_element else None
        app_price = None
        price_element = None
        
        try:
            wait = WebDriverWait(driver, 10)
            button = wait.until(EC.element_to_be_clickable((By.CSS_SELECTOR, 'button.VfPpkd-Bz112c-LgbsSe[aria-label^="See more information on About this"]')))
            button.click()
            
            soup = BeautifulSoup(driver.page_source, 'html.parser')
            in_app_purchase_label = soup.find('div', class_='q078ud', string="In-app purchases")
            
            if in_app_purchase_label:
                price_element = in_app_purchase_label.find_next_sibling('div', class_='reAt0')
        
        except Exception as e:
            print(f"Error processing {link}: {str(e)}")
            app_price = None
        
        if price_element is not None:
            price_element_text = str(price_element.get_text(strip=True))
            price_range_match = re.search(r"\$(\d+\.\d+) - \$(\d+\.\d+)", price_element_text)
            if price_range_match:
              formatted_price_range = f"${price_range_match.group(1)} to ${price_range_match.group(2)}"
            else:
              formatted_price_range = 'Free'
            
            print(f"Making API call for {app_title} with price range: {formatted_price_range}")
            api_response = get_estimated_monthly_price(SEARCH_TERM, app_title, formatted_price_range)
            if api_response:
                response_text = api_response.get('choices')[0].get('text').strip()
                estimated_monthly_price = response_text
                asterisk_price_match = re.search(r"\*(.*?)\*", response_text)
                if asterisk_price_match:
                    app_price = float(asterisk_price_match.group(1))
                else:
                    app_price = None
            else:
                estimated_monthly_price = None
        else:
            estimated_monthly_price = None

        results.append([app_title, app_rating, app_price])
        
    except Exception as e:
      print(f"Error processing {link}: {str(e)}")
    
driver.quit()


results = [entry for entry in results if entry[1] is not None]

app_titles = [app_title for app_title, _, _ in results if app_title is not None]
app_ratings = [app_rating for _, app_rating, _ in results if app_rating is not None]
app_prices = [app_price if app_price is not None else 0 for _, _, app_price in results]

non_zero_prices = [price for price in app_prices if price != 0]
avg_price = sum(non_zero_prices) / len(non_zero_prices) if non_zero_prices else 0




