# Plan for new rhythm probability feature

- The new probability array will contain strings of numbers in text, optionally separated by the : character. There will be 1, 3 or 4 numbers in the string. 2 is not allowed.
- The first number in the string will be initial probability number.
- The next two numbers are the minimum and maximum the probability can take when mutating the probabilities.
- If there is only a single number in the string, then the probabilities are not mutated
- If there are min and max values, then the probabilities should be mutated in the same place they are now.
- If there is optionally a 4th number in the string, that should be used as the mutatedProbabilityRange. If no 4th number is in the string use the mutatedPRobabilityRange in the Part class
- The existing rhythmProbabilities array should be used to hold the current probabilities
