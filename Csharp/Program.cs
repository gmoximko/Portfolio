using System;
using System.IO;
using System.Text;
using System.Collections.Generic;

namespace TestTask
{
    interface Command
    {
        object Execute(object arg);
    }

    class NullCommand : Command
    {
        public object Execute(object arg)
        {
            return null;
        }
    }

    class HelpCommand : Command
    {
        private readonly string helpMessage = "Commands:"
            + Environment.NewLine + "\"Run -h\" - show help message."
            + Environment.NewLine + "\"Run -f filename -m checksum\" - show checksum of file \"filename\"."
            + Environment.NewLine + "\"Run -f filename -m find -s someword\" - show enter of word \"someword\" in file \"filename\".";

        public object Execute(object arg)
        {
            Console.WriteLine(helpMessage);

            return null;
        }
    }

    class FileCommand : Command
    {
        private readonly string filename;

        private FileStream file;

        public FileCommand(string filename)
        {
            this.filename = filename;
        }

        ~FileCommand()
        { 
            if (file != null) file.Close();
        }

        public object Execute(object arg)
        {
            try
            {
                file = File.OpenRead(filename);
            }
            catch (Exception e)
            {
                Console.WriteLine(e.Message);
            }
            
            return file;
        }
    }

    class ChecksumModeCommand : Command
    {
        private const int machineWordLength = 4;

        private BinaryReader reader;

        private ulong checksum;

        public object Execute(object arg)
        {
            if (!(arg is Stream)) return null;
            
            using (reader = new BinaryReader(arg as Stream))
            {
                long length   = reader.BaseStream.Length;
                long position = 0;

                while (position < length)
                {
                    ulong result = 0;

                    var bytes = reader.ReadBytes(machineWordLength);

                    for (int i = machineWordLength - 1; i >= 0; i--)
                    {
                        result <<= 8;

                        result |= (i >= bytes.Length ? 0UL : bytes[i]);
                    }

                    checksum += result;
                    position += machineWordLength;
                }
            }
            
            Console.WriteLine("Checksum is: {0}", checksum);

            return null;
        }
    }

    class FindModeCommand : Command 
    {
        private StreamReader reader;

        ~FindModeCommand()
        {
            if (reader != null) reader.Dispose();
        }

        public object Execute(object arg)
        {
            reader = arg is Stream ? new StreamReader(arg as Stream) : null;

            return reader;
        }
    }

    class WordFindCommand : Command
    {
        private readonly string word;

        private const int bufferSize = 100;

        private char[] buffer;

        private StringBuilder result;

        public WordFindCommand(string word)
        {
            this.word = word;
        }

        public object Execute(object arg)
        {
            if (!(arg is StreamReader)) return null;

            if (String.IsNullOrEmpty(word))
            {
                Console.WriteLine("Can't find empty string!");
                return null;
            }

            result = new StringBuilder();

            buffer = new char[bufferSize * word.Length];

            using (var reader = arg as StreamReader)
            {
                long index = 0;
                int length = buffer.Length;
                int count  = 0;
                int j      = 0;

                do//while (!reader.EndOfStream)
                {
                    for (int k = 0; k < j; k++)
                    { 
                        buffer[k] = buffer[buffer.Length - j + k];
                    }

                    count = reader.ReadBlock(buffer, j, buffer.Length - j) + j;

                    for (int k = j; k < count; k++)
                    {
                        j = j < word.Length && word[j] == buffer[k] ? j + 1 : 0;

                        if (j == word.Length)
                        {
                            result.Append((index - j + 1).ToString() + " ");
                            k     -= (j - 1);
                            index -= (j - 1);
                            j = 0;
                        }

                        index += (buffer[k] >> 8 == 0 ? 1L : 2L);
                    }
                }
                while (count == length);
            }
            
            string temp = result.ToString();

            Console.WriteLine(String.IsNullOrEmpty(temp) ? "Word \"" + word + "\" not found!" : temp);

            return null;
        }
    }

    class CommandFactory
    {
        private readonly string[] commandNames = { "-h", "-f", "-m", "-s" };

        private static CommandFactory instance;

        private CommandFactory() { }

        public static CommandFactory GetInstance()
        {
            instance = instance ?? new CommandFactory();

            return instance;
        }

        public Command GetCommand(string commandName, string parameter)
        {
            if      (commandName == commandNames[0]) return new HelpCommand();
            else if (commandName == commandNames[1]) return new FileCommand(parameter);
            else if (commandName == commandNames[2])
            { 
                if      (parameter == "checksum") return new ChecksumModeCommand();
                else if (parameter == "find")     return new FindModeCommand();
            }
            else if (commandName == commandNames[3]) return new WordFindCommand(parameter);

            return new NullCommand();
        }

        public List<Command> GetCommands(string[] input)
        {
            List<Command> commands = new List<Command>();

            for (int i = 0; i < input.Length; i++)
            {
                for (int j = 0; j < commandNames.Length; j++)
                {
                    if (input[i] == commandNames[j])
                    {
                        string parameter = i + 1 >= input.Length ? "" : input[i + 1];

                        commands.Add(GetCommand(commandNames[j], parameter));
                    }
                }
            }

            return commands;
        }
    }

    class Program
    {
        static void Main(string[] args)
        {
            List<Command> commands = CommandFactory.GetInstance().GetCommands(args);

            object temp = null;

            for (int i = 0; i < commands.Count; i++)
            {
                temp = commands[i].Execute(temp);
            }
        }
    }
}
