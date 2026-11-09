---
name: typescript-preferences
description: Patrick's personal TypeScript coding preferences. Load before writing, reviewing, refactoring, or advising on TypeScript or TSX code.
---

# TypeScript preferences

Apply these preferences when working with TypeScript or TSX. Do not assume conventions when none are explicitly listed in repositories.

- Prefer `const` over `let`: `let` is inferior because it forces you to read the entire code in scope after its declaration to ensure it doesn't get reassigned if you want to make sure you understand the code properly. 
- Prefer named exports over default exports: Named exports make searching for usage by keyword more viable and encourages both naming consistency and uniqueness.
- Minimize the use of `throw` and `try-catch`: Try-catches are essentially go-to with restrictions - They make it so that you need to read an entire method implementation before knowing what code paths can be reached by its invocation and what errors need to be handled. If an error needs to be
propagated out of a method opt for returning. If a particular error needs to be
caught, catch that specific error and throw the rest.  
- Avoid truthy evaluation of `undefined` and/or null Opt for `myVariable ===
undefined` and `myVariable === null` instead: Being explicit avoids ambiguity about whether you missed or covered an extra case by accident.
- Use `??` instead of `||` where possible: Similar to the above - Avoids ambiguity about whether you missed or covered an extra case by accident.
- You can use `null as unknown as <TypeBeingTested> satisfies <TypeItNeedsToAbideBy>` as a means of writing a
"test" to ensure one type satisfies the requirements of another.
- Prefer `as unknown` to `as any`: Better practice from the perspective of always picking the strictest option when there's no tangible downside.
- Prefer `/** */` or `/* */` to multiple `//`s when a comment spans more than 1
line: Makes adding new lines to the comments easier
- Prefer using `type` over `interface`: Keeps syntactic style more 'natively' JavaScript.
- Prefer `satisfies` over `as`: Provides many more type guarantees and type strictness over `as`.
- When an argument's type definition is very complex but the method only uses a
small subset of fields on that type, use `Pick<MyType, ...>` in the argument
type definition to only include the fields the method uses: Abides by the "Interface segregation principal"
- Prefer `| undefined` over `?:` in argument types unless the intention is to
optimize for developer convenience and worrying about accidentally omitting a
parameter is not a risk: Avoids ambiguity as to whether a developer simply didn't see the optional parameter.
- Prefer `globalThis` over `window` or `global`: More standard JavaScript syntax 

## `null as unknown as X satisfies Y`

As mentioned, this can be used as a type guide. See the following example:

```typescript
type User = { id: string; name: string; email: string };
type HasId = { id: string };

// Compiles - User is assignable to HasId
null as unknown as User satisfies HasId;

// TS1360: Type '{ name: string; }' does not satisfy the expected type 'HasId'.
//   Property 'id' is missing in type '{ name: string; }' but required in type 'HasId'.
null as unknown as { name: string } satisfies HasId;
```

Note that this is one instance where an exception can be made for inline linting suppression (E.g. `no-unused-expressions`).

