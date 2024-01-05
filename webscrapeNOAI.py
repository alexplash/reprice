import re
from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

BASE_URL = 'https://play.google.com'
SEARCH_TERM = sys.argv[1] if len(sys.argv) > 1 else ''
SEARCH_URL = f'{BASE_URL}/store/search?q={SEARCH_TERM}&c=apps'

options = webdriver.ChromeOptions()
options.add_argument('headless')
driver = webdriver.Chrome(options=options)

driver.get(SEARCH_URL)

soup = BeautifulSoup(driver.page_source, 'html.parser')
app_links = [BASE_URL + a['href'] for a in soup.select('a.Si6A0c.Gy4nib')][:10]

results = []

for link in app_links:
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
        button = wait.until(EC.element_to_be_clickable((By.CSS_SELECTOR, 'button.VfPpkd-Bz112c-LgbsSe[aria-label^="See more information on About this')))
        button.click()
        
        soup = BeautifulSoup(driver.page_source, 'html.parser')
        in_app_purchase_label = soup.find('div', class_='q078ud', string="In-app purchases")
        
        if in_app_purchase_label:
            price_element = in_app_purchase_label.find_next_sibling('div', class_='reAt0')
            if price_element:
                numeric_values = [float(value) for value in re.findall(r"(\d+\.\d+|\d+)", price_element.text)]
                app_price = max(numeric_values) if numeric_values else None
                
    except Exception as e:
        print(f"Error processing {link}: {str(e)}")
        app_price = None
    
    results.append([app_title, app_rating, app_price])

driver.quit()

results = [entry for entry in results if entry[1] is not None]

app_prices = [app_price if app_price is not None else 0 for _, _, app_price in results]
app_titles = [app_title for app_title, _, _ in results if app_title is not None]
app_ratings = [app_rating for _, app_rating, _ in results if app_rating is not None]

non_zero_prices = [price for price in app_prices if price != 0]
avg_price = sum(non_zero_prices) / len(non_zero_prices) if non_zero_prices else 0




