# Minimalistic bitcoin wallet

## Commands:
- address — shows generated address
- balance — shows balance of funds on generated address
- help — shows list of commands
- send ADDR amount — sends a specified amount of funds to address that user specified
- exit — terminates program

## Easy to test with Docker:
- Run service in docker:
  `docker-compose -f docker/docker-compose.yml up`
- Attach to container to interact with the script:
  `docker attach bitcoin_wallet`
