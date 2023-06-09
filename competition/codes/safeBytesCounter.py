import collections
import sys

def main():
  print(sys.argv)
    # Open the binary file in read-only mode
  with open(sys.argv[1], 'rb') as f:
      # Read the entire file into a bytes object
      data = f.read()

  # Create a counter object to count the frequency of each 4-bit pattern
  counter = collections.Counter()

  # Iterate over each 4-byte pattern in the file and increment its count
  for i in range(len(data) - 3):
      # Extract the 4-byte pattern from the current position in the file
      pattern = data[i:i+4]
      # Increment the count for this pattern
      counter[pattern] += 1

  # Print the results
  for pattern, count in counter.items():
      print(f'{pattern.hex()} appears {count} times')

  print('safe bytes amount: ', len([(pattern, count) for pattern, count in counter.items() if count == 5]) * 4)



if __name__ == "__main__":
    main()