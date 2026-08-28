import argparse
import json
from routing_engine import load_dataset, Router

def main():
    p=argparse.ArgumentParser()
    p.add_argument('data')
    p.add_argument('origin')
    p.add_argument('destination')
    p.add_argument('--departure',type=int,default=0, help='Ignored in V4; kept for CLI compatibility')
    args=p.parse_args()
    ds=load_dataset(args.data)
    router=Router(ds)
    result=router.route_between_stop_ids(args.origin,args.destination,args.departure)
    print(json.dumps(router.format_result(result), ensure_ascii=False, indent=2))

if __name__=='__main__':
    main()
