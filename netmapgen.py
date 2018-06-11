#!/usr/bin/env python3

import sys
import json
import subprocess


def help():
    print("netmapgen <hosts>")
    print("  hosts - space separated ip/dns name list")


def routegen(target):
    ret = subprocess.run(
        ["mtr", "-nrc", "2", target, "--json"],
        stdout=subprocess.PIPE,
        universal_newlines=True,
        check=True)

    return json.loads(ret.stdout)


def graph_print_dot(links):
    print("graph {")
    print("  rankdir=LR;")
    for link in links:
        print(link)
    print("}")


def graph_print_dot_file(links, filename="graph.dot"):
    print("Write dot graph to {}".format(filename))
    with open(filename, 'w+') as fd:
        fd.write("graph {")
        fd.write("  rankdir=LR;")
        for link in links:
            fd.write(' ' + link)
        fd.write("}")


def dot_to_png(filename="graph.dot"):
    print("Convert {} to png: {}".format(filename, "graph.png"))
    subprocess.run(
        [
            "dot", filename,
            "-Goverlap=false",
            "-Tpng", "-o", "graph.png"],
        check=True
    )


def main(argv):
    if len(argv) < 2:
        help()

    routes = {}

    for i in range(len(argv)):
        if i > 0:
            target = argv[i]
            if not routes.get(target):
                routes[target] = routegen(target)

    links = set()

    for route_key in routes:
        route = routes[route_key]
        host = route["report"]["mtr"]["src"]
        hubs = route["report"]["hubs"]
        prev = host

        for hub in hubs:
            link = "\"{}\" -- \"{}\"".format(prev, hub["host"])
            links.add(link)
            prev = hub["host"]

    graph_print_dot(links)
    graph_print_dot_file(links)
    dot_to_png()


if __name__ == '__main__':
    main(sys.argv)
