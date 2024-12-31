import yaml
import sys
for item in sys.argv[1:]:
  print(item)

  with open(item, 'r') as file:
    contents = yaml.safe_load(file)
    print(contents)

  with open(item, 'w') as outfile:
    yaml.dump(contents, outfile)
