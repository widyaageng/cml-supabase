import time

if __name__=="__main__":
    while True:
        try:
            print(time.time())
            time.sleep(1)
        except KeyboardInterrupt:
            print("terminated")
            break
        except Exception as e:
            print(e)
            raise e