### User inputs price token amount for 2 tokens and amount they wish to purchase
### Output price impact
### Python is so fun lol

def calculate_swap(TokenA_reserve, TokenB_reserve, TokenB_to_swap):
    k = TokenA_reserve * TokenB_reserve
    delta_TokenA = (TokenA_reserve * TokenB_to_swap) / (TokenB_reserve + TokenB_to_swap)
    return delta_TokenA

# Get initial values from user
TokenA_reserve = float(input("Enter the initial amount of TOKENA in the pool: "))
TokenB_reserve = float(input("Enter the initial amount of TOKENB in the pool: "))

# Determine how much TOKENB the user wishes to swap
TokenB_to_swap = float(input("Enter the amount of TOKENB you wish to swap for TOKENA: "))

# Calculate the results
delta_TokenA = calculate_swap(TokenA_reserve, TokenB_reserve, TokenB_to_swap)

# Display the results
print(f"For {TokenB_to_swap} TOKENB, you will receive approximately {delta_TokenA:.2f} TOKENA.")

# Calculate and display the actual swap price
actual_swap_price = delta_TokenA / TokenB_to_swap
print(f"Actual swap price: 1 TOKENB for {actual_swap_price:.2f} TOKENA.")

# Calculate the price impact
initial_price = TokenA_reserve / TokenB_reserve
price_impact = (actual_swap_price - initial_price) / initial_price * 100
print(f"Price impact: {price_impact:.2f}%")
