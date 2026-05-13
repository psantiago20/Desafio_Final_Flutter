import asyncio
from playwright.async_api import async_playwright

async def main():
    async with async_playwright() as p:
        browser = await p.chromium.launch()
        page = await browser.new_page()
        
        # Listen to all console events
        page.on("console", lambda msg: print(f"CONSOLE: {msg.text}"))
        
        try:
            print("Navigating...")
            await page.goto("http://localhost:8000/app/")
            print("Waiting for 5 seconds to let flutter initialize...")
            await asyncio.sleep(5)
            
            # Print page content
            content = await page.content()
            # print("Content:", content[:500])
        except Exception as e:
            print("Error navigating:", e)
        finally:
            await browser.close()

if __name__ == "__main__":
    asyncio.run(main())
