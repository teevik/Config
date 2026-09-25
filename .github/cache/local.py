"""Talk to the homelab's credential-free retention socket."""

import json
import os
import socket


def request(operation, **arguments):
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as connection:
        connection.settimeout(600)
        connection.connect(os.environ["NIX_CACHE_LOCAL_SOCKET"])
        connection.sendall(json.dumps({"operation": operation, **arguments}).encode())
        connection.shutdown(socket.SHUT_WR)
        with connection.makefile("rb") as response:
            payload = response.read(1024 * 1024 + 1)
    if len(payload) > 1024 * 1024:
        raise ValueError("Oversized cache response")
    result = json.loads(payload)
    if "error" in result:
        raise ValueError(result["error"])
    return result["result"]
