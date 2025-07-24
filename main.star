redis_module = import_module("github.com/kurtosis-tech/redis-package/main.star")

def run(plan, args={}):
    validate_args(plan, args)
    plan.print("Test name: {0}".format(args["test_name"]))

    plan.print("Starting Redis package...")
    redis_output = redis_module.run(plan)

    node_count = get_node_count(args)
    log_level = args.get("log_level", "debug")
    node_configs = {}
    node_index = 0
    for p in args["participants"]:
        for i in range(p["count"]):
            service_name = "node-{0}-{1}-{2}".format(node_index, p["image"].split(":")[0], i)
            node_configs[service_name] = ServiceConfig(
                image=p["image"],
                env_vars={
                    "REDIS_HOST": redis_output.hostname,
                    "REDIS_PORT": str(redis_output.port_number),
                    "RUST_LOG": log_level,
                    "TEST_NAME": args["test_name"],
                    "NODE_COUNT": str(node_count),
                    "NODE_INDEX": str(node_index),
                }
            )
            node_index += 1
    plan.add_services(node_configs)

def validate_args(plan, args):
    plan.print("Validating arguments...")
    if "test_name" not in args or not args["test_name"]:
        fail("test_name is required and cannot be empty")
    
    if "participants" not in args or not args["participants"]:
        fail("participants is required and cannot be empty")

    for p in args["participants"]:
        if "image" not in p or not p["image"]:
            fail("image is required and cannot be empty")
        if "count" not in p or not p["count"]:
            fail("count is required and cannot be empty")
        if p["count"] < 1:
            fail("count must be greater than 0")
    plan.print("Arguments validation completed")

def get_node_count(args):
    n = 0
    for p in args["participants"]:
        n += p["count"]
    return n
