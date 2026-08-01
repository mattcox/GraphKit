//
//  PriorityQueue.swift
//  GraphKit
//
//  Created by Matt Cox on 01/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

/// A minimum ordered priority queue, backed by a binary heap.
///
/// The queue supports duplicate elements, and makes no attempt to reduce the
/// priority of an element that is already enqueued. An algorithm that needs to
/// do so should enqueue the element again, and discard the stale entry when it
/// is dequeued.
///
internal struct PriorityQueue<Priority: Comparable, Element> {
/// The elements in the queue, arranged as a binary heap.
///
/// The element with the lowest priority is stored first, and the children of
/// the element at an offset are stored at twice that offset, plus one and
/// two.
///
	internal var storage: [(priority: Priority, element: Element)]

/// Initialize an empty queue.
///
	internal init() {
		self.storage = []
	}

/// Indicates whether the queue contains no elements.
///
	internal var isEmpty: Bool {
		storage.isEmpty
	}

/// Reserves enough storage to hold the provided number of elements.
///
/// - Parameters:
///   - count: The number of elements to reserve storage for.
///
	internal mutating func reserveCapacity(_ count: Int) {
		storage.reserveCapacity(count)
	}

/// Inserts an element into the queue.
///
/// - Parameters:
///   - element: The element to insert.
///   - priority: The priority to order the element by.
///
	internal mutating func insert(_ element: Element, priority: Priority) {
		storage.append((priority: priority, element: element))

		var child = storage.count - 1
		while child > 0 {
			let parent = (child - 1) / 2
			guard storage[child].priority < storage[parent].priority else {
				break
			}

			storage.swapAt(child, parent)
			child = parent
		}
	}

/// Removes and returns the element with the lowest priority.
///
/// - Returns: The element with the lowest priority, along with its priority,
///   or nil if the queue is empty.
///
	internal mutating func removeMinimum() -> (priority: Priority, element: Element)? {
		guard let minimum = storage.first else {
			return nil
		}

		storage.swapAt(0, storage.count - 1)
		storage.removeLast()

		var parent = 0
		while true {
			let left = parent * 2 + 1
			let right = left + 1
			var lowest = parent

			if left < storage.count, storage[left].priority < storage[lowest].priority {
				lowest = left
			}

			if right < storage.count, storage[right].priority < storage[lowest].priority {
				lowest = right
			}

			guard lowest != parent else {
				break
			}

			storage.swapAt(parent, lowest)
			parent = lowest
		}

		return minimum
	}
}
