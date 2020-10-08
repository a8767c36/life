(module
	;; (import "./test.mjs" "log" (func $log.info.i32         (param i32 i32)))
	;; (import "./test.mjs" "log" (func $log.info.i32.i32     (param i32 i32 i32)))
	;; (import "./test.mjs" "log" (func $log.info.i32.i32.i32 (param i32 i32 i32 i32)))

	(memory 0)

	;; takes location:vector and produces the exact memaddr:memaddr
	;; each game cell is stored in a byte (more than needed to have some extra room)
	(func $addr (param $x i32) (param $y i32) (result i32)
		;; we store each location in a spiralic way in linear memory

		(local.get $x)
		(i32.const 0)
		(i32.lt_s)
		(if (then
			(i32.const -1)
			(local.get $x)
			(i32.mul)
			(local.get $y)
			(call $addr)
			(i32.const 1)
			(i32.add)
			(return)
		))

		(local.get $y)
		(i32.const 0)
		(i32.lt_s)
		(if (then
			(local.get $x)
			(local.get $y)
			(i32.const -1)
			(i32.mul)
			(call $addr)
			(i32.const 2)
			(i32.add)
			(return)
		))

		;; the formula is: 4*((x+y)*(x+y+1)/2 + y)
		(local.get $x)
		(local.get $y)
		(i32.add)
		(local.get $x)
		(local.get $y)
		(i32.const 1)
		(i32.add)
		(i32.add)
		(i32.mul)
		(i32.const 2)
		(i32.div_u)
		(local.get $y)
		(i32.add)
		(i32.const 4)
		(i32.mul)
		(return)
	)

	;; generates a new map for the next game step
	(func $new_map
		;; each cell has 1 byte
		;; each byte holds 8 bit
		;; we can use bits (old_state, new_state, 6x 0)
		;;
		;; we proceed in spiralic ways to walk all locations
		;;
		;; for x in [0:Infinity) do
		;;   for y in [0:x] do
		;;     if addr(x, y) > 3 * memory.size + 16 then
		;;       return ; we're done
		;;     fi
		;;
		;;     new_cell( (x-y),  y)
		;;     new_cell(-(x-y),  y)
		;;     new_cell( (x-y), -y)
		;;     new_cell(-(x-y), -y)
		;;   done
		;; done

		(local $x i32) (local $y i32)
		(loop $repeat_x
			(i32.const 0)
			(local.set $y)
			(loop $repeat_y
				(local.get $x)
				(local.get $y)
				(call $addr)
				(i32.mul (memory.size) (i32.const 65536))
				(i32.const 3)
				(i32.mul)
				(i32.const 16)
				(i32.add)
				(i32.gt_u)
				(if (then return))

				(local.get $x)
				(local.get $y)
				(i32.sub)
				(local.get $y)
				(call $new_cell)
				;;
				(i32.const -1)
				(local.get $x)
				(local.get $y)
				(i32.sub)
				(i32.mul)
				(local.get $y)
				(call $new_cell)
				;;
				(local.get $x)
				(local.get $y)
				(i32.sub)
				(local.get $y)
				(i32.const -1)
				(i32.mul)
				(call $new_cell)
				;;
				(i32.const -1)
				(local.get $x)
				(local.get $y)
				(i32.sub)
				(i32.mul)
				(local.get $y)
				(i32.const -1)
				(i32.mul)
				(call $new_cell)

				(local.get $y) (i32.const 1) (i32.add)
				(local.set $y)
				(local.get $y) (local.get $x) (i32.le_u)
				(br_if $repeat_y)
			)
			(local.get $x) (i32.const 1) (i32.add)
			(local.set $x)
			(br $repeat_x)
		)
	)

	(func $new_cell (param $x i32) (param $y i32)
		(local $neighbors i32)
		;; if map_get(x, y) == 1 then
		;;   neighbors = neighbors(x, y)
		;;   if neighbors == 2 then new_map_set(x, y, 1) fi
		;;   if neighbors == 3 then new_map_set(x, y, 1) fi
		;; fi
		;; if map_get(x, y) == 0 then
		;;   neighbors = neighbors(x, y)
		;;   if neighbors == 3 then new_map_set(x, y, 1) fi
		;; fi

		(if (call $map_get (local.get $x) (local.get $y)) (then
			(local.set $neighbors (call $neighbors (local.get $x) (local.get $y)))
			;; (call $log.info.i32.i32.i32 (i32.const 0) (local.get $x) (local.get $y) (local.get $neighbors))
			(if (i32.eq (local.get $neighbors) (i32.const 2)) (then (call $new_map_set (local.get $x) (local.get $y) (i32.const 1))))
			(if (i32.eq (local.get $neighbors) (i32.const 3)) (then (call $new_map_set (local.get $x) (local.get $y) (i32.const 1))))
		) (else
			(local.set $neighbors (call $neighbors (local.get $x) (local.get $y)))
			(if (i32.eq (local.get $neighbors) (i32.const 3)) (then (call $new_map_set (local.get $x) (local.get $y) (i32.const 1))))
		))
	)

	(func $neighbors (param $x i32) (param $y i32) (result i32)
		(local.get $x) (i32.const -1) (i32.add)
		(local.get $y) (i32.const -1) (i32.add)
		(call $map_get)
		(local.get $x) (i32.const -1) (i32.add)
		(local.get $y) (i32.const  0) (i32.add)
		(call $map_get)
		(local.get $x) (i32.const -1) (i32.add)
		(local.get $y) (i32.const +1) (i32.add)
		(call $map_get)
		(local.get $x) (i32.const  0) (i32.add)
		(local.get $y) (i32.const -1) (i32.add)
		(call $map_get)
		;;(local.get $x) (i32.const  0) (i32.add)
		;;(local.get $y) (i32.const  0) (i32.add)
		;;(call $map_get)
		(local.get $x) (i32.const  0) (i32.add)
		(local.get $y) (i32.const +1) (i32.add)
		(call $map_get)
		(local.get $x) (i32.const +1) (i32.add)
		(local.get $y) (i32.const -1) (i32.add)
		(call $map_get)
		(local.get $x) (i32.const +1) (i32.add)
		(local.get $y) (i32.const  0) (i32.add)
		(call $map_get)
		(local.get $x) (i32.const +1) (i32.add)
		(local.get $y) (i32.const +1) (i32.add)
		(call $map_get)
		(i32.add) (i32.add) (i32.add) (i32.add)
		(i32.add) (i32.add) (i32.add) (; (i32.add) ;)
	)

	(func $map_get (param $x i32) (param $y i32) (result i32)
		(local $addr i32)
		(local.get $x)
		(local.get $y)
		(call $addr)
		(local.set $addr)

		(local.get $addr)
		(memory.size)
		(i32.const 65536)
		(i32.mul)
		(i32.le_u)
		(if (result i32)
			(then (i32.load8_u (local.get $addr)))
			(else (i32.const 0))
		)

		(i32.const 1)
		(i32.and)
	)

	(func $new_map_set (param $x i32) (param $y i32) (param $state i32)
		(local $addr i32)
		(local.get $x)
		(local.get $y)
		(call $addr)
		(local.set $addr)

		(loop $check_space
			(memory.size)
			(local.get $addr)
			(i32.lt_u)
			(if (then
				(i32.const 1)
				(memory.grow) (drop)
				(br $check_space)
			))
		)

		;; (call $log.info.i32.i32.i32 (i32.const 1) (local.get $x) (local.get $y) (local.get $state))
		;; sanitize state (0 or 1)
		(local.get $state)
		(if (result i32) (then (i32.const 1)) (else (i32.const 0)))
		(local.set $state)

		(local.get $addr)
		(local.get $addr)
		(i32.load8_u)
		;; (local.get $state) (i32.const 1) (i32.shl) (i32.and)
		(local.get $state) (i32.const 1) (i32.shl) (i32.or)
		(i32.store8)
	)

	(func $update_map
		;; takes all the new bits and moves them to the old bits

		(local $addr i32)
		(local $cell i32)
		(loop $iterate
			(local.get $addr)
			(memory.size)
			(i32.const 65536)
			(i32.mul)
			(i32.ge_u)
			(if (then (return)))

			(local.get $addr)
			(local.get $addr)
			(i32.load8_u)
			(local.tee $cell)
			(i32.const 1)
			(i32.shr_u)
			(i32.store8)

			(local.set $addr (i32.add (i32.const 1) (local.get $addr)))
			(br $iterate)
		)
	)

	(func $tick
		(call $new_map)
		(call $update_map)
	)

	(func $map_set (param $x i32) (param $y i32) (param $state i32)
		(local $addr i32)
		(local.get $x) (local.get $y) (call $addr) (local.set $addr)

		(loop $check_space
			(memory.size) (i32.const 65536) (i32.mul)
			(local.get $addr)
			(i32.lt_u)
			(if (then
				(i32.const 1)
				(memory.grow) (drop)
				(br $check_space)
			))
		)

		(local.get $addr) (local.get $state) (i32.store8)
	)

	(export "step" (func $tick))
	(export "get" (func $map_get))
	(export "set" (func $map_set))
)