# Repository

[Repository](http://github.com/markiv/repository) is a simple construct to help build asynchronous data-driven interfaces with SwiftUI and its `Observable` pattern – all with the minimum amount of ceremony.

You can think of a repository as an "instant `ViewModel`" for those very common scenarios where your app needs to fetch and display information.

## Observable Swift Concurrency

Basically, a repository object is initialized with a closure that provides some output type for a given input type (or `Void` when no input is needed). That can be a network fetch or any other kind of asynchronous operation.

```swift
@State private var repo = Repository {
    try await API.todos()
}
```

This observable repository now provides a method to `load` the output and a single source of truth `state` property.

```swift
public enum State {
    case ready
    case loading
    case success(Output)
    case failure(Error)
}
```

Here's a practical example, with a repository created and owned by a view in its own `@State`:

```swift
struct ContentView: View {
    @State private var repo = Repository {
        try await API.todos()
    }

    var body: some View {
        switch repo.state {
        case .ready, .loading: ProgressView("Loading...")
            .task { await repo.load() }
        case let .failure(error): ErrorView(error)
        case let .success(output): List(output) {...}
        }
    }
}
```

If you prefer, you can create named, specialized subclasses of `Repository` for reuse in your codebase:

```swift
class TodoRepository: Repository<Void, [Todo]> {
    convenience init() {
        self.init { try await API.todos() }
    }
}
```

## Environment Friendly

And of course, you can also pass repositories through the SwiftUI environment, for example when you need to share a single source of truth to multiple views:

```swift
WindowGroup {
    ContentView()
        .environment(TodoRepository())
}

struct ContentView: View {
    @Environment(TodoRepository.self) private var repo
    ⋮
```

This can even be done "anonymously" (without subclassing), if you prefer:

```swift
WindowGroup {
    ContentView()
        .environment(Repository { try await API.todos() })
}

struct ContentView: View {
    @Environment(Repository<Void, [Todo]>.self) private var repo

    var body: some View {
        switch repo.state {
        ⋮
```

## Refreshing

By default, a repository will not load unnecessarily once it has successfully loaded. You can force a reload by passing `refresh: true` to the `load` method. Here's an example that connects this behavior to a `List` view's pull-to-refresh control:

```swift
List(todos) { todo in
    ⋮
}
.refreshable { await repo.load(refresh: true) }
```

## Optional Input

So far, we've seen examples of repositories that didn't take any input. Below is an example with an input – in this case a detail view for a given todo identifier.

```swift
struct DetailView: View {
	let todoID: Int
	
    @State private var repo = Repository { id in
        try await API.todo(id: id)
    }

    var body: some View {
        switch repo.state {
        case .ready, .loading: ProgressView("Loading...")
            .task { repo.input = todoID }
        ⋮
```

Conveniently, assigning a new value to the `input` property will cause the repository to refresh automatically. And inputs can be of any type – simple values, tuples, structs, etc.
### Convenience Accessors
A repository has a single source of truth – its `state` property. For convenience, however, it also offers simple accessors *into* that state: `isLoading`, `output` and `error.`

```swift
if let output = repo.output {
    Text(output)
} else if repo.isLoading {
     ProgressView("Loading...")  
} else { ...
```
## Some Batteries Included
### Bonus Extensions
`Repository` is not limited to network loading tasks, though that's probably its most common use case. That's why the library includes a couple of bonus generic extensions that make fetching `Decodable`s from the network a little more delightful.

Any `Decodable` can now be initialized straight from a `URL` or `URLRequest`:

```swift
let todo = try await Todo(from: "https//api/todos/1")
```

And as you might have noticed in the example above, we used a string instead of a `URL(string: "...")!`. The library includes a `URL` extension that lets us express `URL`s succinctly with string literals (we deliberately limit this to string **literals** only – balancing convenience and type safety).

## Faster Than Vibe Coding
### Fetch Data & Display It in Seconds
With all that in place, and if we wanted to, we could create a quick prototype or proof-of-concept in no time at all. Below is a _fully functional_ example, complete with error handling and progress indicator:

```swift
struct QuickAndDirtyPrototype: View {
    @State private var repo = Repository {
        try await Todo(from: "https://jsonplaceholder.typicode.com/todos/10")
    }

    var body: some View {
        switch repo.state {
        case .ready, .loading: ProgressView("Loading...")
            .task { await repo.load() }
        case let .failure(error): Text(error.localizedDescription)
        case let .success(todo):
            Text(todo.title).strikethrough(todo.completed)
        }
    }
}

struct Todo: Codable {
	let id, userId: Int
	let title: String
	let completed: Bool
}
```
