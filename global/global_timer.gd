extends Node

var timer: Timer

var queue: Array = []
var timer_id_counter: int = 0

func _ready() -> void:
    timer = Timer.new()
    timer.timeout.connect(_on_timer_timeout)
    timer.wait_time = 0.1
    timer.autostart = true
    add_child(timer)

func add_timer(duration: float, callback: Callable) -> int:
    timer_id_counter += 1
    queue.append({
        "duration": duration,
        "callback": callback,
        "timer_id": timer_id_counter
    })

    return timer_id_counter

func remove_timer(timer_id: int) -> void:
    for i in range(queue.size()):
        if queue[i].timer_id == timer_id:
            queue.remove_at(i)
            break

func _on_timer_timeout() -> void:
    process_queue(timer.wait_time)

func process_queue(delta: float) -> void:
    var i := 0
    while i < queue.size():
        var entry = queue[i]
        entry.duration -= delta
        
        if entry.duration <= 0:
            entry.callback.call()
            queue.remove_at(i)
        else:
            i += 1

