
/// A regex that matches a spoiler tag.
final spoiler = RegExp(r'\|\|(.+?)\|\|');

/// A regex that matches a github link.
final githubLink = RegExp(r'https?:\/\/github\.com\/([\w-]+\/[\w.-]+)\/blob\/(.+?)\/(.+?)#L(\d+)[~-]?L?(\d*)');
