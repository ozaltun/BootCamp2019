# box.py
'''
Introductory Labs: The Standard Library. Auxiliary file (do not
modify).
'''

from itertools import combinations
import random
import time
import sys



def isvalid(roll, remaining):
    '''
    Check to see whether or not a roll is valid. That is, check if there
    exists a combination of the entries of 'remaining' that sum up to
    'roll'.

    Parameters:
        roll (int): The value of a dice roll, between 2 and 12
                    (inclusive).
        remaining (list): The list of the numbers that still need to be
                          removed before the box can be shut.

    Returns:
        True if the roll is valid.
        False if the roll is invalid.
    '''
    if roll not in range(2, 13):
        return False
    for i in xrange(1, len(remaining) + 1):
        if any([sum(combo) == roll for combo in combinations(remaining, i)]):
            return True
    return False


def parse_input(player_input, remaining):
    """Convert a string of numbers into a list of unique integers, if possible.
    Then check that each of those integers is an entry in the other list.

    Parameters:
        player_input (str): A string of integers, separated by spaces.
            The player's choices for which numbers to remove.
        remaining (list): The list of the numbers that still need to be
            removed before the box can be shut.

    Returns:
        A list of the integers if the input was valid.
        An empty list if the input was invalid.
    """
    try:
        choices = [int(i) for i in player_input.split()]
        if len(set(choices)) != len(choices):
            raise ValueError
        if any([number not in remaining for number in choices]):
            raise ValueError
        return choices
    except ValueError:
        return []




def roll_dice(remaining):
    if sum(remaining)<= 6:
        return random.randint(1, 6)
    else:
        dice_1, dice_2 = random.randint(1, 6), random.randint(1, 6)
        return dice_1+dice_2

def play_round(remaining, dice_roll, time_left):
    print('Numbers left: ', remaining)
    print('Roll:', dice_roll)
    print('Seconds left:', time_left)
    player_input = input("Numbers to eliminate: ")
    print('')
    print('')
    print('')
    choices = parse_input(player_input, remaining)
    print('')
    print('')
    valid_round = True
    if not choices or (sum(choices) != dice_roll):
        valid_round = False
    return choices, valid_round


start_time = time.time()
if len(sys.argv) < 3:
    print('Not enough arguments!!')

playerName = sys.argv[1]
timeLimit = float(sys.argv[2])

remaining = [i for i in range(1, 10)]

time_left = timeLimit - (time.time()-start_time)
counter = 0

while time_left >0:

    dice_roll = roll_dice(remaining)
    choices, valid_round = play_round(remaining, dice_roll, time_left)

    if valid_round == False:
        print('Your inputs were wrong, please try again.')
    else:
        remaining = [i for i in remaining if i not in choices]
        counter += 1

    if not remaining:
        print('Score for player {}: '.format(playerName), counter)
        print('Time Played: ', time.time()-start_time)
        print('Congratulations!!, you shut the box!!')
        break


    time_left = timeLimit - (time.time()-start_time)

if remaining:
    print('Sorry, you weren\'t able to shut the box. You ran out of time. Please try again')
