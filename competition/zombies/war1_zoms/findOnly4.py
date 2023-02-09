str = """
41 
EB F3 
BB CC CC 
50 
BB CC CC 
5E 
81 C6 06 02
39 1C 
75 F8 
89 0C 
41 
EB F3 
BB CC CC 
50 
5E 
81 C6 06 02
39 1C 
75 F8 
89 0C 
41 
EB F3 
BB CC CC 
50 
BB CC CC 
5E 
81 C6 06 02
39 1C 
75 F8 
89 0C 
41 
EB F3 
BB CC CC 
50 
5E 
81 C6 06 02
39 1C 
75 F8 
89 0C 
41 
EB F3 
BB CC CC 
50 
5E 
81 C6 06 02
39 1C 
75 F8 
89 0C 
41 
EB F3 
BB CC CC 
"""

targetStr = """
81 C6 06 02
39 1C
75 F8
89 0C
41
EB F3
BB CC CC 
"""

arr = str.replace('\n', ' ').split(' ')
arr = [i for i in arr if i != '']

print(arr)
print(targetStr.replace('\n', '').replace(' ', ''))
for i in range(len(arr)):
    tempArr = arr[i:i + 4]
    if len(tempArr) == 4:
        tempStr = "".join([j for j in tempArr])
        print(tempStr)
        if "".join(arr).count(tempStr) <= 4 and targetStr.replace('\n', '').replace(' ', '').find(tempStr) != -1:
            print("nice: ", tempStr)
