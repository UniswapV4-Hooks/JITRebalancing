import math

def getSqrtPricex96FromPrice(price):
    # sqrtPriceX96 = floor(sqrt(A / B) * 2 ** 96)
    # uint160 public constant SQRT_PRICE_1_1 = 79228162514264337593543950336;
    # Q_n = D_n * (2^k) where k = 96
    # sqrtPrice_
    return math.sqrt(price)*math.pow(2,96)

if __name__ == "__main__":
    # ask the user for the price
    inputPrice = input("Enter the price: ")
    print(f'sqrtPricex96({inputPrice}) {int(getSqrtPricex96FromPrice(float(inputPrice)))}')
