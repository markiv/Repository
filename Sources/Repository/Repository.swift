//
//  Repository.swift
//  Repository
//
//  Created by Vikram Kriplaney on 17.06.2025.
//

import Foundation

@MainActor
@Observable public class Repository<Input, Output: Sendable> {
    /// Enumerates the possible states of this repository.
    public enum State {
        /// The repository is ready to do work.
        case ready
        /// The repository is doing some work.
        case loading
        /// The repository successfully produced some output.
        case success(Output)
        /// The repository failed with an error.
        case failure(Error)
    }

    /// The state of this repository.
    public var state = State.ready

    /// Input for this repository's work. Can be `Void` if no input is needed.
    /// Assigning a new value causes the repository to reload.
    public var input: Input? {
        didSet { Task { await load(refresh: true) } }
    }

    /// A closure type that provides output for a given input.
    public typealias Loader = @concurrent (Input) async throws -> Output
    private let loader: Loader

    /// Initializes this repository with a closure type that provides output for a given input.
    public init(loader: @escaping Loader) {
        self.loader = loader
    }

    /// Performs the loading work, trying to produce output for the given input.
    public func load(refresh: Bool = false) async {
        guard let input else { return } // ignore request if there's no input
        if case .loading = state { return } // ignore request if already loading
        if !refresh, case .success = state { return } // ignore request if already loaded (unless forced to refresh)
        do {
            state = .loading
            state = try await .success(loader(input))
        } catch {
            state = .failure(error)
        }
    }
}

public extension Repository where Input == Void {
    /// Performs the loading work where no input is needed.
    func load(refresh: Bool = false) async {
        if case .loading = state { return } // ignore request if already loading
        if !refresh, case .success = state { return } // ignore request if already loaded (unless forced to refresh)
        do {
            state = .loading
            state = try await .success(loader(()))
        } catch {
            state = .failure(error)
        }
    }
}

// MARK: - Convenience accessors
public extension Repository {
    /// A convenience accessor for this repository's loading state.
    @inlinable var isLoading: Bool {
        if case .loading = state { return true }
        return false
    }

    /// A convenience accessor for this repository's output, if any.
    @inlinable var output: Output? {
        if case let .success(output) = state { return output }
        return nil
    }

    /// A convenience accessor for this repository's error, if any.
    @inlinable var error: Error? {
        if case let .failure(error) = state { return error }
        return nil
    }
}
