import itertools

##The first function here takes a color "r", and checks for t-term arithmetic progressions beginning on the left edge entry
def pdwredgecheck(r,t,coloring):
    #j indexes across possible jump sizes
    for j in range(1,floor((len(coloring)-1)/(t-1))+1):
        #checks to see if the t-term progressions is monochromatic
        if all(r == coloring[j*k] for k in range(0,t)):
            return 1
    return 0

def v3pdw(t):
    #even parameter will track lengths of the even words
    even = 2
    #odd parameter will track lengths of the odd words
    odd = 1
    #S is our list of suitable odd colorings
    S = [[0],[1]]
    #T is our list of suitable even colorings
    T = [[0,0],[1,1]]
    #We iteratively scan all possible colorings of length 2 larger until each list is empty
    while len(S) !=0:
        newodd = []
        for x in S:
            #The colorings are palindromic, so we either append 0s or 1s at each end
            y = [0] + copy(x) + [0]
            z = [1] + copy(x) + [1]
            
            if pdwredgecheck(0,3,y) == 0:
                    newodd.append(y)
            if pdwredgecheck(1,t,z) == 0:
                    newodd.append(z)
        S = newodd
        #The entries of S, with the two appended 0s and 1s have additional length 2
        odd = odd + 2
    while len(T) !=0:
        neweven = []
        for x in T:
            y = [0] + copy(x) + [0]
            z = [1] + copy(x) + [1]
            if pdwredgecheck(0,3,y) == 0:
                    neweven.append(y)
            if pdwredgecheck(1,t,z) == 0:
                    neweven.append(z)
        T = neweven
        #The entries of T, with the two appended 0s and 1s have additional length 2
        even = even + 2
    return (min(even,odd)-1, max(even,odd)-1)