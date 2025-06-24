@testable import Repository
import Testing

@MainActor
@Test func loadingState() async throws {
    let repo = Repository { "Hello, World!" }

    #expect(repo.isLoading == false)
    #expect(repo.output == nil)
    #expect(repo.error == nil)
    await repo.load()
    #expect(repo.isLoading == false)
    #expect(repo.output == "Hello, World!")
}

@MainActor
@Test func autoLoadWithNewInput() async throws {
    let sleepyDoubler = Repository { (input: Int) in
        try? await Task.sleep(nanoseconds: 100)
        return input * 2
    }

    sleepyDoubler.input = 10
    #expect(sleepyDoubler.output == nil)
    while sleepyDoubler.output == nil {
        await Task.yield()
    }
    #expect(sleepyDoubler.output == 20)

    sleepyDoubler.input = 20
    await Task.yield()
    #expect(sleepyDoubler.output == nil)
    while sleepyDoubler.output == nil {
        await Task.yield()
    }
    #expect(sleepyDoubler.output == 40)
}

@MainActor
@Test func errorState() async throws {
    let repo = Repository { throw CancellationError() }
    await repo.load()
    #expect(repo.isLoading == false)
    #expect(repo.output == nil)
    #expect(repo.error is CancellationError)
}
