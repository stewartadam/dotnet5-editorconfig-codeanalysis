using System;

/**
 * Class that purposefully includes some code smells to trigger analysis
 * warnings during build.
 *
 * Remember to copy one of the global.*.json files as global.json (and adjust
 * the version) to ensure the desired SDK version is used during build.
 */
namespace CodeAnalysisDemo
{
    public class Book
    {
        // This should be readonly
        private string[] _Pages;

        // This should use int type instead of Int32
        private readonly Int32 _PageCount;

        public Book(string[] pages)
        {
            _Pages = pages;
            _PageCount = pages.Length;
        }

        // Formatting is wrong on the opening curley brace
        public string[] Pages {
            get { return _Pages; }
        }
    }

    internal class Program
    {
        // Needs accessibility modifiers
        static void Main(string[] args)
        {
            Console.WriteLine("Hello World!");
        }
    }
}
