# If unsure of token tax breakdown, just enter 1 tax, 'slippage' and enter number

def calculate_swap(tokenA_reserve, tokenB_reserve, amount_to_swap, token_chosen):
    if token_chosen == 'A':
        # Using formula for swapping Token A for Token B
        delta_tokenB = (tokenB_reserve * amount_to_swap) / (tokenA_reserve + amount_to_swap)
        return -amount_to_swap, delta_tokenB
    else:
        # Using formula for swapping Token B for Token A
        delta_tokenA = (tokenA_reserve * amount_to_swap) / (tokenB_reserve + amount_to_swap)
        return delta_tokenA, -amount_to_swap

def apply_taxes(amount, tax_details):
    net_amount = amount
    lp_amount = 0
    print("\nApplying Taxes:")
    for tax_name, tax_percentage in tax_details.items():
        tax_value = net_amount * tax_percentage / 100
        if tax_name.lower() in ["lp", "liquidity", "liquidity pool"]:
            lp_amount += tax_value
        net_amount -= tax_value
        print(f"{tax_name}: -{tax_value:.2f}")
    return net_amount, lp_amount

# Get initial values from user
tokenA_reserve = float(input("Enter the initial amount of Token A in the pool: "))
tokenB_reserve = float(input("Enter the initial amount of Token B in the pool: "))

# Get tax details from user
tax_count = int(input("Enter the number of taxes: "))
tax_details = {}
for _ in range(tax_count):
    tax_name = input(f"Enter the name of tax {_ + 1}: ")
    tax_percentage = float(input(f"Enter the percentage for {tax_name}: "))
    tax_details[tax_name] = tax_percentage

# Decide which token the user wishes to swap
chosen_token = input("\nDo you want to spend Token A or Token B? (Enter 'A' or 'B'): ").upper()

# Determine how much of the chosen token the user wishes to swap
amount_to_swap = float(input(f"Enter the total amount of Token {chosen_token} you initially wish to use (before tax deductions): "))

# Apply taxes and get net Token amount and LP tax amount
net_amount, lp_tax_amount = apply_taxes(amount_to_swap, tax_details)

# Add the LP tax amount to the respective token reserve
if chosen_token == 'A':
    tokenA_reserve += lp_tax_amount
else:
    tokenB_reserve += lp_tax_amount

# Calculate the results
delta_tokenA, delta_tokenB = calculate_swap(tokenA_reserve, tokenB_reserve, net_amount, chosen_token)

# Display the results
print(f"\nFor a net amount of {net_amount:.2f} Token {chosen_token} (after taxes),")
if delta_tokenA > 0:
    print(f"You will receive {delta_tokenA:.2f} Token A.")
if delta_tokenB > 0:
    print(f"You will receive {delta_tokenB:.2f} Token B.")

# Calculate and display the actual swap price
if chosen_token == 'A':
    actual_swap_price = delta_tokenB / net_amount
    print(f"Actual swap price: 1 Token A for {actual_swap_price:.2f} Token B.")
else:
    actual_swap_price = delta_tokenA / net_amount
    print(f"Actual swap price: 1 Token B for {actual_swap_price:.2f} Token A.")

# Calculate the price impact
initial_price = tokenA_reserve / tokenB_reserve
price_impact = (actual_swap_price - initial_price) / initial_price * 100
print(f"Price impact: {price_impact:.2f}%")
